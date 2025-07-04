//
// Created by maks on 04.07.25.
//

#include <fstream>
#include <iostream>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>
#include <fcntl.h>
#include <linux/limits.h>
#include <sys/types.h>
#include <random>
#include <sys/stat.h>
#include <chrono>
#include <thread>

#include "types.cpp"

#define LOGGING_ENABLED
#define DEBUG_MODE

#define server_wait_for(x) force_wait_for_confirm(); {x;} confirm();

safe_memory_header* header;
char* data;
unsigned long id;
unsigned long cycle_mseconds;

inline void confirm(){

    command_execution_status status = header->execution_status;
    status = combine_enums(status, command_execution_status::RESULT_CONFIRMED);
    header->execution_status = status;
}

inline bool server_active(){
    return header->srv_status !=server_status::INACTIVE;
}

inline void wait_for_server(){
    while(header->srv_status != server_status::WAITING)
        wait_for(cycle_mseconds);
}

inline void wait_for_command_ready(){
    while(header->execution_status != command_execution_status::NONE)
        wait_for(cycle_mseconds);
}

inline command_execution_status wait_for_execution(){
    command_execution_status status = header->execution_status;
    while(!is_executed(status))
    {
        wait_for(cycle_mseconds);
        status = header->execution_status;
    }
    return status;
}

template<typename T>
inline command_execution_status send_command(command c, T input_data){
    wait_for_command_ready();
    reinterpret_cast<T *>(data)[0] = input_data;
    header->source_client_id = id;
    header->next_command = c;
    if(command_returns(c))
    {
        const auto status = wait_for_execution();
        confirm();
        return status;
    }
    else
    {
        wait_for(cycle_mseconds);
        return command_execution_status::NONE;
    }
}

inline command_execution_status send_command(command c){
    wait_for_command_ready();
    header->source_client_id = id;
    header->next_command = c;
    if(command_returns(c))
    {
        const auto status = wait_for_execution();
        confirm();
        return status;
    }
    else
    {
        wait_for(cycle_mseconds);
        return command_execution_status::NONE;
    }
}

inline void force_wait_for_confirm(){
    wait_for_command_ready();
    header->next_command = command::WAIT_FOR_CONFIRM;
}

inline command_execution_status request_id(unsigned long& result){
    if(!server_active())
        return command_execution_status::EXECUTED;

    wait_for_command_ready();

    header->next_command = command::REQUEST_ID;

    const auto status = wait_for_execution();
    result = *reinterpret_cast<unsigned long *>(data);
    confirm();
    return status;
}

command_execution_status open_session(){
    if(!server_active())
        return command_execution_status::EXECUTED;

    return send_command(command::REQUEST_SESSION);
}

bool owns_session(){
    return header->session_id == id;
}

bool acknowledge(){
    if(!server_active() || !owns_session())
        return false;

    send_command(command::ACKNOWLEDGE);

    return true;
}

void close_connection(const shm_handle<safe_memory_header, char>& shm_handle){
    munmap(shm_handle.ptr, shm_handle.header->data_length + sizeof(safe_memory_header));
    close(shm_handle.file_descriptor);
}

const program_switch save_swt("-s", "--save", switch_arguments::MULTIPLE);
const program_switch get_swt("-g", "--get", switch_arguments::MULTIPLE);
const program_switch stop_swt("-k", "--kill", switch_arguments::NONE);
const program_switch getsave_swt("-gs", "--get-save", switch_arguments::MULTIPLE);
const program_switch check_activity_swt("", "--ping", switch_arguments::NONE);


int main(const int argc, char** argv){

    shm_handle<safe_memory_header, char> shm_handle;
    shm_handle.shm_name = "/svpath_shm";

    // Get shared memory file descriptor
    shm_handle.file_descriptor = shm_open(shm_handle.shm_name, O_RDWR, 0666);
    if(shm_handle.file_descriptor == -1){
        std::cerr << "shm_open() failed: " << std::strerror(errno) << '\n';
        std::cerr.flush();
        close(shm_handle.file_descriptor);
        return errno;
    }

    // Get shm size
    struct stat st;
    if(fstat(shm_handle.file_descriptor, &st) == -1){
        std::cerr << "fstat() failed: " << strerror(errno) << '\n';
        std::cerr.flush();
        close(shm_handle.file_descriptor);
        return 1;
    }

    // Map memory
    shm_handle.ptr = mmap(nullptr, st.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_handle.file_descriptor, 0);
    if(shm_handle.ptr == MAP_FAILED){
        std::cout << "mmap() failed: "<< strerror(errno) << '\n';
        std::cerr.flush();
        close(shm_handle.file_descriptor);
        return 1;
    }

    shm_handle.header = static_cast<safe_memory_header*>(shm_handle.ptr);
    shm_handle.data = reinterpret_cast<char*>(shm_handle.header + 1);
    header = shm_handle.header;
    data = shm_handle.data;
    cycle_mseconds = header->check_mseconds;

    wait_for_server();
    auto status = request_id(id);

    if(!is_succeed(status)){
        std::cerr<< "Couldn't obtain id";
        close_connection(shm_handle);
        return 1;
    }

    const size_t data_length = header->data_length;
    const auto buffer = new char[data_length];

    status = open_session();

    if(!is_succeed(status)){
        std::cerr << "Failed to connect to the server!";
        close_connection(shm_handle);
        return 1;
    }

    for(int index = 1; index < argc; index++){
        if(!acknowledge()){
            std::cerr << "Lost server connection!";
            close_connection(shm_handle);
            return 1;
        }

        if(std::string_view str(argv[index]); save_swt.equals(str)){
            index+=1;
            while(index < argc && argv[index][0] != '-'){
                force_wait_for_confirm(); 
                size_t path_length = strlen(argv[index]); 
                memcpy(shm_handle.data, argv[index], path_length); 
                shm_handle.data[path_length] = '\0';
                confirm();

                status = send_command(command::SAVE);

                if(!is_succeed(status)){
                    std::cerr<< "Failed while saving paths!\n";
                    send_command(command::CLOSE_SESSION);
                    close_connection(shm_handle);
                    return 1;
                }
                index+=1;
            }
            index-=1;
        }
        else if(get_swt.equals(str)){
            index+=1;
            bool first = true;
            while(index < argc && argv[index][0] != '-'){
                int num;
                if(!try_convert(argv[index], num)){
                    std::cerr << '"'<< argv[index] << '"' << " is not a number!";
                    send_command(command::CLOSE_SESSION);
                    return 1;
                }
                status = send_command<unsigned long>(command::GET, num);

                if(!is_succeed(status)){
                    std::cerr<< "Failed while reading paths!\n";
                    send_command(command::CLOSE_SESSION);
                    close_connection(shm_handle);
                    return 1;
                }

                if(first)
                    first = false;
                else
                    std::cout << ' ';
                std::cout << std::string_view(shm_handle.data, data_length);

                index+=1;
            }
            index-=1;
        }
        else if(getsave_swt.equals(str)){
            index+=1;
            bool first = true;
            while(index < argc && argv[index][0] != '-'){
                int num;
                if(!try_convert(argv[index], num)){
                    std::cerr << '"'<< argv[index] << '"' << " is not a number!";
                    send_command(command::CLOSE_SESSION);
                    return 1;
                }
                status = send_command<unsigned long>(command::GET_SAVE, num);

                if(!is_succeed(status)){
                    std::cerr<< "Failed while reading paths!\n";
                    send_command(command::CLOSE_SESSION);
                    close_connection(shm_handle);
                    return 1;
                }

                if(first)
                    first = false;
                else
                    std::cout << ' ';
                std::cout << std::string_view(shm_handle.data, data_length);

                index+=1;
            }
            index-=1;
        }
        else if(stop_swt.equals(str)){
            send_command(command::STOP);
        }
    }
    if(server_active() && owns_session())
        send_command(command::CLOSE_SESSION);
    close_connection(shm_handle);
    return 0;
}
