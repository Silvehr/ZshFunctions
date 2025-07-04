#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <linux/limits.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#include <random>
#include <chrono>
#include <thread>

#include "types.cpp"

template<typename THeader, typename TData> class shm_manager{
    shm_handle<THeader, TData> _shm_handle;
    size_t _data_section_length;
    bool _open;

    public:
    shm_manager(const char* shm_name, size_t data_section_length){
        _shm_handle.shm_name = shm_name;
        _data_section_length = data_section_length;
        _open = false;
    }

    THeader* header(){
        return _shm_handle.header;
    }

    TData* data(){
        return _shm_handle.data;
    }

    bool is_open() { return _open; }

    int open_mem(){
        _shm_handle.file_descriptor = shm_open(_shm_handle.shm_name, O_CREAT | O_RDWR, 0666);

        if(_shm_handle.file_descriptor == -1){
            return errno;
        }

        ftruncate(_shm_handle.file_descriptor, _data_section_length + sizeof(safe_memory_header));
        _shm_handle.ptr = mmap(nullptr, _data_section_length + sizeof(safe_memory_header), PROT_READ | PROT_WRITE, MAP_SHARED, _shm_handle.file_descriptor, 0);
        _shm_handle.header = reinterpret_cast<safe_memory_header*>(_shm_handle.ptr);
        _shm_handle.data = reinterpret_cast<char*>(_shm_handle.header + 1);
        _open = true;

        memset(_shm_handle.ptr, 0, _data_section_length + sizeof(safe_memory_header));

        return 0;
    }

    void close_mem(){
        munmap(_shm_handle.ptr, _data_section_length + sizeof(safe_memory_header));
        shm_unlink(_shm_handle.shm_name);
        close(_shm_handle.file_descriptor);
        _open = false;
    }
};

class page_stack{
    char* _ptr;

    int _start;
    int _end;
    int _count;

    public:

    const int size;
    const size_t page_size;

    page_stack(int page_count, size_t page_size) : page_size(page_size), size(page_count){
        _start = 0;
        _end = 0;
        _count = 0;
        _ptr = new char[page_size * page_count];
    }

    ~page_stack(){
        delete[] _ptr;
    }

    char* current(){
        return _ptr + _end * page_size;
    }

    char* at(int index){
        if(index >= _count || index < 0)
            return nullptr;

        index -= _end - 1;
        if(index < 0)
            index = size + index;
        
        return &_ptr[index * page_size];
    }

    void move(){
        if(_end == size)
            _end = 0;
        else
            _end += 1;

        if(_count != size)
            _count+=1;

        if(_end == _start)
        {
            _start += 1;

            if(_start == size)
                _start = 0;
        }
    }

    bool consume(){
        if(_count == 0)
            return false;
        
        if(_end == 0)
            _end = size - 1;
        else
            _end -= 1;

        if(_count != 0)
            _count -= 1;

        return true;
    }
};

class svpath_service{
    unsigned long _session_id;
    const int _check_mseconds;
    const int _cycle_count_before_timeout;
    const int _wait_cycles_before_timeout;

    page_stack* _stack;
    shm_manager<safe_memory_header, char>* _shm;

    bool _running;

    public:
    svpath_service(int stored_path_count, size_t max_path_length, int check_mseconds, int cycle_count_before_timeout, int wait_cycles_before_timeout, const char* shm_name):
        _stack(new page_stack(stored_path_count, max_path_length)),
        _shm(new shm_manager<safe_memory_header, char>(shm_name, stored_path_count * max_path_length)),
        _check_mseconds(check_mseconds),
        _cycle_count_before_timeout(cycle_count_before_timeout),
        _wait_cycles_before_timeout(wait_cycles_before_timeout)
    {
        _session_id = 0;
        _running = false;
    }

    ~svpath_service(){
        delete _shm;
        delete _stack;
    }

    int run(){
        int mem_open_result = _shm->open_mem();

        if(mem_open_result != 0){
            return mem_open_result;
        }

        auto header = _shm->header();
        auto data = _shm->data();
        auto ul_data = reinterpret_cast<unsigned long*>(data);
        int timeout_cycle_counter = 0;

        header->data_length = _stack->page_size;
        header->check_mseconds = _check_mseconds;
        header->srv_status = server_status::WAITING;

        _running = true;

        while(_running){
            header->next_command = command::NONE;
            header->execution_status = command_execution_status::NONE;
            command c = command::NONE;
            unsigned long source_client_id;
            bool returns;
            bool command_succeeded = true;

            if(_session_id == 0){
                #ifdef LOGGING_ENABLED
                    std::cout << "[info] waiting for REQUEST_ID, REQUEST_SESSION...\n";
                #endif

                while(c == command::NONE){
                    wait_for(_check_mseconds);
                    c = header->next_command;
                }

                returns = command_returns(c);
                header->execution_status = combine_enums(header->execution_status, command_execution_status::ACCEPTED);
                source_client_id = header->source_client_id;

                switch(c){
                    case command::REQUEST_ID:
                        *ul_data = generate_id();

                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] generated id: " << *ul_data << '\n';
                        #endif

                        break;

                    case command::REQUEST_SESSION:
                        _session_id = source_client_id;
                        header->session_id = source_client_id;
                        header->srv_status = server_status::BUSY;

                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] settled new session: " << _session_id << '\n';
                        #endif
                        break;

                    default:
                        header->srv_status = server_status::WAITING;
                        break;
                }
            }
            else{
                #ifdef LOGGING_ENABLED
                    std::cout << "[info] waiting for SAVE GET STOP CLOSE_SESSION...\n";
                #endif

                while(c == command::NONE){
                    wait_for(_check_mseconds);

                    if(timeout_cycle_counter == _cycle_count_before_timeout){
                        timeout_cycle_counter = 0;
                        close_session(header);
                        #ifdef LOGGING_ENABLED
                            std::cout << "[warning] session timeout\n";
                        #endif
                        break;
                    }

                    c = header->next_command;
                    timeout_cycle_counter+=1;
                }

                returns = command_returns(c);
                source_client_id = header->source_client_id;
                timeout_cycle_counter = 0;
                header->execution_status = combine_enums(header->execution_status, command_execution_status::ACCEPTED);

                if(source_client_id == _session_id){
                    switch (c)
                    {
                    case command::ACKNOWLEDGE:
                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] acknowledge from id: " << _session_id << "\n";
                        #endif
                    break;

                    case command::CLOSE_SESSION:
                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] closing session with id: " << _session_id << "\n";
                        #endif

                        close_session(header);

                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] closed session\n";
                        #endif
                    break;

                    case command::GET:{
                            returns = true;

                            #ifdef LOGGING_ENABLED
                            std::cout << "[info] path is read by: " << _session_id << "\n";
                            #endif
                            char* src = _stack->at(*ul_data - 1);
                            if(src == nullptr)
                            {
                                command_succeeded = false;
                            }
                            else
                            {
                                size_t src_length = strlen(src);
                                memcpy(data, src, src_length);
                                data[src_length] = '\0'; // Ensure null-termination
                            }

                            #ifdef LOGGING_ENABLED
                                std::cout << "[info] path read\n";
                            #endif
                        }
                    break;

                    case command::SAVE:
                        #ifdef LOGGING_ENABLED
                        std::cout << "[info] path is being saved by: " << _session_id << "\n";
                        #endif

                        memcpy(_stack->current(), data, _stack->page_size);
                        _stack->move();

                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] saved path\n";
                        #endif
                    break;

                    case command::GET_SAVE:
                        {
                            char* to_return = _stack->at(*ul_data - 1);
                            if(to_return == nullptr)
                            {
                                command_succeeded = false;
                            }
                            else
                            {
                                size_t to_return_length = strlen(to_return);
                                memcpy(_stack->current(), to_return, to_return_length);
                                memcpy(data, to_return, to_return_length);
                                data[to_return_length] = '\0'; // Ensure null-termination
                                _stack->move();
                            }
                        }
                        break;

                    case command::WAIT_FOR_CONFIRM:
                        #ifdef LOGGING_ENABLED
                        std::cout << "[info] forcing waiting for confiramtion by: " << _session_id << "\n";
                        #endif

                        while(!is_confirmed(header->execution_status))
                            wait_for(_check_mseconds);
                    break;

                    case command::STOP:
                        #ifdef LOGGING_ENABLED
                            std::cout << "[info] server is being stopped\n";
                        #endif

                        _running = false;
                        header->srv_status = server_status::INACTIVE;
                    break;
                    
                    default:
                        break;
                    }
                }
            }

            if(returns)
            {
                if(command_succeeded)
                    header->execution_status = command_execution_status::SUCCEED;
                else
                    header->execution_status = command_execution_status::EXECUTED;
                
                wait_for_confirmation(header);
            }
        }

        #ifdef LOGGING_ENABLED
        std::cout << "[info] server has been stopped\n";
        #endif

        _shm->close_mem();
        return 0;
    }

    void force_mem_close(){
        if(_shm->is_open()){
            _shm->close_mem();
        }
    }

    private:
    void close_session(safe_memory_header* header){
        _session_id = 0;
        header->execution_status = command_execution_status::NONE;
        header->session_id =0;
        header ->srv_status = server_status::WAITING;
        header->next_command = command::NONE;
    }

    unsigned long generate_id(){
        static std::mt19937_64 rng(std::random_device{}());
        unsigned long id = 0;
        do {
            id = static_cast<unsigned long>(rng());
        } while(id == 0);
        return id;
    }

    bool wait_for_confirmation(const safe_memory_header* header){
        #ifdef LOGGING_ENABLED
            std::cout << "[info] waiting for confirmation...\n";
        #endif
        int wait_cycles_counter = 0;
        while(true){
            if(is_confirmed(header->execution_status))
            {
                #ifdef LOGGING_ENABLED
                std::cout << "[info] confirmed\n";
                #endif
                return true;
            }
            if(wait_cycles_counter == _wait_cycles_before_timeout)
            {
                #ifdef LOGGING_ENABLED
                std::cout << "[warning] confirmation timeout\n";
                #endif
                return false;
            }
                
            wait_for(_check_mseconds);
            wait_cycles_counter += 1;
        }
    }
};

const program_switch capacity_swt("-c", "--capacity", switch_arguments::SINGLE);
const program_switch path_length_swt("-l", "--path-length", switch_arguments::SINGLE);
const program_switch stop_swt("-t", "--check-time", switch_arguments::NONE);
const program_switch cbt_swt("", "--cycles-before-timeout", switch_arguments::NONE);
const program_switch cbwt_swt("", "--cycles-before-wait-timeout", switch_arguments::NONE);

int main(const int argc, const char* argv[])
{
    int path_count = 10;
    size_t path_max_length = PATH_MAX;
    int check_mseconds = 3;
    int cycle_count_before_timeout = 10;
    int wait_cycles_before_timeout = 30;

    for(int index = 1; index < argc; index++){
        if(capacity_swt.equals(argv[index])){
            index+=1;
            if(!try_convert(argv[index], path_count)){
                std::cerr << "Invalid value for --capacity: " << argv[index] << "\n";
                return 1;
            }
        }
        else if(path_length_swt.equals(argv[index])){
            index+=1;
            std::stoul(argv[index]);
            if(!try_convert<size_t>(argv[index], path_max_length)){
                std::cerr << "Invalid value for --capacity: " << argv[index] << "\n";
                return 1;
            }
        }
        else if(stop_swt.equals(argv[index])){
            index+=1;
            if(!try_convert(argv[index], check_mseconds)){
                std::cerr << "Invalid value for --capacity: " << argv[index] << "\n";
                return 1;
            }
        }
        else if(cbt_swt.equals(argv[index])){
            index+=1;
            if(!try_convert(argv[index], cycle_count_before_timeout)){
                std::cerr << "Invalid value for --capacity: " << argv[index] << "\n";
                return 1;
            }
        }
        else if(cbwt_swt.equals(argv[index])){
            index+=1;
            if(!try_convert(argv[index], wait_cycles_before_timeout)){
                std::cerr << "Invalid value for --capacity: " << argv[index] << "\n";
                return 1;
            }
        }
        else{
            std::cerr << "Unknown switch: " << argv[index] << "\n";
        }
    }

    svpath_service safe_srv(path_count, path_max_length, check_mseconds, cycle_count_before_timeout, wait_cycles_before_timeout, "/svpath_shm");
    safe_srv.force_mem_close();
    return safe_srv.run();
}