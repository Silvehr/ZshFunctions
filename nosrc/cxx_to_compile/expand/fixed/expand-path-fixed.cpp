#include <cstring>
#include <iostream>
#include <limits.h>
#include <linux/limits.h>
#include <stdexcept>
#include <string_view>
#include <unistd.h>

struct string_split{
    private:
    const char* str;
    int len;

    public:
    string_split() : str(nullptr), len(0){}
    string_split(const char* str, int len) : str(str), len(len){}

    void operator=(string_split& rhs){
        std::swap(str, rhs.str);
        len = rhs.len;    
    }

    void operator=(string_split&& rhs){
        str = rhs.str;
        len = rhs.len; 
    }

    char operator[](int index) const {
        if(index < 0 || index >= len)
            throw std::out_of_range("index is out of range");

        return str[index];
    }

    int length() const {
        return len;
    }

    const char* string() {
        return str;
    }
};

struct string_split_iterator
{
    private:
    const char* str;
    const int str_len;
    const char splitter;
    const bool from_end;
    
    // <split_beg, split_end)
    int split_beg, split_end;
    bool initialized = false;

    public:
    string_split_iterator(char* str, int str_len, char splitter, bool from_end) : str(str), str_len(str_len), splitter(splitter), from_end(from_end){
    }

    bool move_next() {
        if(!initialized){
            split_end = str_len;
            split_beg = str_len;
            initialized = true;
        }

        if(from_end){
            if(split_beg == 0)
                return false;
        }
        else{
            if(split_end == str_len)
                return false;
        }

        set_next();
        return true;
    }
    
    string_split current() const{
        return string_split(&str[split_beg], split_end - split_beg);
    }

    private:
    void set_next(){
        if(from_end){
            split_beg--;
            split_end = split_beg;
            while(split_beg > 0){
                split_beg--;
                if(str[split_beg] == splitter){
                    split_beg++;
                    break;
                }
            }
        }
        else{
            split_beg = split_end + 1;
            while(split_end < str_len){
                split_end++;
                if(str[split_end] == splitter){
                    break;
                }
            }
        }
    }
};

// Tries to convert given string to number. Parsed result is being passed into <result> variable
// Returns true if all characters were digits
bool try_convert(const std::string_view &str, int str_len, int &result)
{
    result = 0;
    int index = 0;
    while (index != str_len)
    {
        int digit = (str[index] - 48);
        if (digit < 0 || digit > 9) return false;
        result = result * 10 + digit;

        index++;
    }

    return true;
}

// Checks if given string matches pattern "<number>.." and returns number
// Returns -1 if the string doesn't match the pattern
inline int get_up_count(string_split& split)
{
    const char* str = split.string();
    int length = split.length();

    if (length < 2) return -1;

    if (str[length - 1] == '\0') length -= 1;

    if (str[length - 1] != '.' || str[length - 2] != '.') return -1;

    if (length == 2) return 1;

    int result;
    if (!try_convert(str, length - 2, result)) return -1;

    return result;
}

int main()
{
    int argc = 2;
    char** argv = new char*[1] { new char[11]{"/home/maks"}};

    if (argc == 1)
    {
        char *tmp = get_current_dir_name();
        std::cout << tmp;
        return 0;
    }

    // Current Working Directory
    char *cwd;
    int cwd_len = 0;
    int cwd_part_count = 0;

    // cwd is not initialized by default. Requesting for current path is time consuming operation
    // It reduces the time spent on waiting for os to respond and give the control back
    bool initialized = false;

    // Size of the buffer that keeps <split>'s
    int path_parts_buffer_size = 0;

    char *current_arg = argv[1];
    int total_character_count = strlen(current_arg);
    int total_path_part_count = 0;
    bool absolute = current_arg[0] == '/';

    // Initialize cwd
    if(absolute){
        // WARNING: this creates pointer with malloc(). Should be deleted with free()
        cwd = get_current_dir_name();
        cwd_len = strlen(cwd);
        total_character_count += cwd_len;

        // Calculate amount of path parts
        for (int str_i = 0; str_i < cwd_len; ++str_i)
        {
            if (cwd[str_i] == '/') 
                ++total_path_part_count;
        }
    }

    bool previous_character_was_separator = current_arg[total_character_count - 1] == '/';

    for(int argv_index = 2; argv_index < argc; argv_index++){
        current_arg = argv[argv_index];
        int current_arg_len = strlen(current_arg);
        total_character_count += strlen(current_arg);
        

        // Calculate amount of path parts
        for (int str_i = 0; str_i < current_arg_len; ++str_i)
        {
            if (current_arg[str_i] == '/'){
                if(previous_character_was_separator)
                    continue;
                previous_character_was_separator = true;
                ++total_path_part_count;
            }
            else {
                previous_character_was_separator = false;
            }
        }
    }

    string_split* path_part_array = new string_split[total_path_part_count];
    int skips_left = 0, path_part_array_index = 0;

    if(absolute){
        string_split_iterator iter(cwd, cwd_len, '/', false);
        while(iter.move_next()){
            path_part_array[path_part_array_index++] = iter.current();
        }
    }

    for (int argv_index = 1; argv_index < argc; argv_index++){
        char *current_arg = argv[argv_index];
        int arg_len = strlen(current_arg);

        string_split_iterator iter(current_arg, arg_len, '/', false);

        while(iter.move_next()){
            auto current = iter.current();
            int up_count = get_up_count(current);
            if(up_count != -1){
                path_part_array_index -= up_count;
            }
            else {
                path_part_array[path_part_array_index++] = current;
            }
        }
    }

    for(int split_index = 0; split_index < path_part_array_index - 1; split_index++){
        std::cout.write(path_part_array[split_index].string(), path_part_array[split_index].length());
        std::cout << '/';
    }

    std::cout.write(path_part_array[path_part_array_index - 1].string(), path_part_array[path_part_array_index - 1].length());

    delete[] path_part_array;

    // You can't delete not initialized pointer
    if (initialized) free(cwd);
}
