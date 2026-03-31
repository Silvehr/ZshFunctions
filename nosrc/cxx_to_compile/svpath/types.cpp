#include<string>
#include <atomic>

#include <chrono>
#include <thread>

enum class switch_arguments{
    NONE = 0,
    SINGLE = 1,
    MULTIPLE = 2
};

struct program_switch{

    const std::string short_switch;
    const std::string long_switch;
    const switch_arguments multiple_args;

    program_switch() :
        multiple_args(switch_arguments::NONE)
        {}

    program_switch(std::string&& short_switch, std::string&& long_switch, switch_arguments args) :
        short_switch(short_switch),
        long_switch(long_switch),
        multiple_args(multiple_args)
    {}

    [[nodiscard]] bool equals(const std::string_view& str) const{
        if(str.empty())
            return false;

        std::string comp_str;
        if(str.length() == long_switch.length()){
            comp_str = long_switch;
        }
        else if(str.length() == short_switch.length()){
            comp_str = short_switch;
        }
        else return false;

        for(int index = 0; index < str.length(); index++){
                if(str[index] != comp_str[index])
                    return false;
            }

        return true;
    }
};

enum struct command : char
{
    //  No command is currently processed
    NONE = 0,

    // Request from client for id
    REQUEST_ID = 0b1000001,

    // Opens command session with server
    // Has to be called, otherwise server will not respond to any command sent by client
    REQUEST_SESSION = 0b1000010,

    // Closes session with server
    // If client doesn't send any commands for few seconds timeout happens and session is closed
    CLOSE_SESSION = 0b0000011,

    // Used to keep session alive
    ACKNOWLEDGE = 0b0000100,

    // Save location
    SAVE = 0b1000101,

    // Lock server until client confirms or server timeouts
    WAIT_FOR_CONFIRM = 0b0000110,

    // Get location
    GET = 0b1000111,

    // Pulls specified path and pushes it as last
    GET_SAVE = 0b1001000,

    // Stop server
    STOP = 0b0001001
};

enum class command_execution_status : char{
    NONE = 0,
    ACCEPTED = 0b0000001,
    EXECUTED = 0b0000011,
    SUCCEED = 0b0000111,
    RESULT_CONFIRMED = 0b0011011,
};

enum class server_status : char{
    INACTIVE = 0,
    WAITING = 1,
    BUSY = 2,
    STOPPING = 3,
};

struct path_data{
    size_t length;
};

struct alignas(alignof(unsigned long)) safe_memory_header{
    volatile unsigned long source_client_id;
    volatile unsigned long session_id;
    volatile size_t data_length;
    volatile unsigned int check_mseconds;
    volatile command next_command;
    volatile command_execution_status execution_status;
    volatile server_status srv_status;
};

template<typename THeader, typename TData> struct shm_handle{
    void* ptr;

    THeader* header;
    TData* data;

    int file_descriptor;
    const char* shm_name;
};

inline bool is_executed(const command_execution_status status){
    return static_cast<command_execution_status>(static_cast<char>(status) & static_cast<char>(command_execution_status::EXECUTED)) == command_execution_status::EXECUTED;
}

inline bool is_succeed(const command_execution_status status){
    return static_cast<command_execution_status>(static_cast<char>(status) & static_cast<char>(command_execution_status::SUCCEED)) == command_execution_status::SUCCEED;
}

inline bool is_confirmed(const command_execution_status status){
    return static_cast<command_execution_status>(static_cast<char>(status) & static_cast<char>(command_execution_status::RESULT_CONFIRMED)) == command_execution_status::RESULT_CONFIRMED;
}

inline bool command_returns(const command c){
    return (static_cast<char>(c) & 64) != 0;
}

std::string command_str(const command c){
    switch(c){

        case command::ACKNOWLEDGE:
            return "ACKNOWLEDGE";

        case command::CLOSE_SESSION:
            return "CLOSE SESSION";

        case command::GET:
            return "GET";

        case command::GET_SAVE:
            return "GET-SAVE";

        case command::NONE:
            return "NONE";

        case command::REQUEST_ID:
            return "REQUEST ID";

        case command::REQUEST_SESSION:
            return "REQUEST SESSION";

        case command::SAVE:
            return "SAVE";

        case command::WAIT_FOR_CONFIRM:
            return "SAVE LOCK";

        case command::STOP:
            return "STOP";
    }

    return "UNDEFINED";
}

bool try_convert(const char *str, int &result)
{
    result = 0;
    int index = 0;
    while (str[index] != '\0')
    {
        const int digit = str[index] - 48;
        if (digit < 0 || digit > 9) return false;
        result = result * 10 + digit;

        index++;
    }

    return true;
}

template<typename TInteger>
bool try_convert(const char *str, TInteger &result){
    result = 0;
    int index = 0;
    while (str[index] != '\0')
    {
        const int digit = str[index] - 48;
        if (digit < 0 || digit > 9) return false;
        result = result * 10 + digit;

        index++;
    }

    return true;
}

template <typename E> E combine_enums(E lhs, E rhs){
    return static_cast<E>(static_cast<char>(lhs) | static_cast<char>(rhs));
}

inline void wait_for(unsigned long milliseconds){
    std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
}
