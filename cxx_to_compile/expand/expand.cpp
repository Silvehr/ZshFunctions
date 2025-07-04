#include <cstring>
#include <iostream>
#include <limits.h>
#include <linux/limits.h>
#include <string>
#include <unistd.h>

struct split
{
        std::string_view str;
        bool to_print;

        split() {}

        split(std::string_view str, bool to_print) : str(str), to_print(to_print) {}
};

// splits string with <splitter> from <str> and puts <split>'s into given buffer
int split_to_split_buffer(char splitter, char *str, int str_len, split *split_buffer)
{
    if (str[str_len - 1] == '\0') str_len -= 1;

    int split_beg = 0;
    int split_end = 0;

    int buffer_index = 0;

    if (str[0] == '/')
    {
        split_beg++;
        split_end++;
    }

    while (split_end < str_len)
    {
        if (str[split_end] == splitter)
        {
            split_buffer[buffer_index++] = split(std::string_view(&str[split_beg], split_end - split_beg), true);
            split_beg = split_end + 1;
        }

        split_end++;
    }

    int last_split_len = str_len - split_beg;

    if (last_split_len > 0)
    {
        split_buffer[buffer_index] = split(std::string_view(&str[split_beg], str_len - split_beg), true);
        return buffer_index + 1;
    }
    else { return buffer_index; }
}

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
inline int get_up_count(const std::string_view &str)
{
    int length = str.length();

    if (length < 2) return -1;

    if (str[length - 1] == '\0') length -= 1;

    if (str[length - 1] != '.' || str[length - 2] != '.') return -1;

    if (length == 2) return 1;

    int result;
    if (!try_convert(str, length - 2, result)) return -1;

    return result;
}

int main(int argc, char **argv)
{
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

    // Flag that determines if any of paths is relative
    bool any_relative = false;

    // Size of the buffer that keeps <split>'s
    int path_parts_buffer_size = 0;

    // Calculate space required for keeping path parts
    for (int argv_index = 1; argv_index < argc; argv_index++)
    {
        char *current_arg = argv[argv_index];
        int arg_len = strlen(current_arg);

        if (arg_len == 0) continue;

        bool absolute = false;
        if (current_arg[0] == '/') { absolute = true; }
        else { any_relative = true; }

        // It is incremented beacuse when there is relative path, there is no leading '/'
        int path_part_count = absolute ? 0 : 1;

        // Initialize cwd
        if (!absolute && !initialized)
        {
            // WARNING: this creates pointer with malloc(). Should be deleted with free()
            cwd = get_current_dir_name();
            cwd_len = strlen(cwd);

            // Calculate amount of path parts
            for (int str_i = 0; str_i < cwd_len; ++str_i)
            {
                if (cwd[str_i] == '/') ++cwd_part_count;
            }

            initialized = true;
        }

        // Calculate amount of current path parts
        for (int str_i = 0; str_i < arg_len; ++str_i)
        {
            if (current_arg[str_i] == '/') ++path_part_count;
        }

        // Check if it is the biggest count
        if (path_part_count > path_parts_buffer_size) path_parts_buffer_size = path_part_count;
    }

    // It stores splitted
    split *path_parts;

    if (!any_relative) { path_parts = new split[path_parts_buffer_size]; }
    else
    {
        path_parts_buffer_size += cwd_part_count;
        path_parts = new split[path_parts_buffer_size];

        // If there is at least one path that is relative, the first few slots of buffer are filled
        // with splitted cwd. The remaining space is used for both relative and absolute paths
        split_to_split_buffer('/', cwd, cwd_len, path_parts);
    }

    bool first = true;

    for (int argv_index = 1; argv_index < argc; argv_index++)
    {
        char *current_arg = argv[argv_index];
        int arg_len = strlen(current_arg);

        // I have no idea how to handle empty paths
        if (arg_len == 0)
        {
            std::cout << ' ';
            continue;
        }

        bool absolute = current_arg[0] == '/';

        if (any_relative)
            // The remaining space for paths
            split_to_split_buffer('/', current_arg, arg_len, &path_parts[cwd_part_count]);
        else
            split_to_split_buffer('/', current_arg, arg_len, path_parts);

        // This value says where is the end of splitted cwd, so processing absolute paths will not
        // override any of the cwd split
        int limit = absolute ? cwd_part_count : 0;

        // How many path elements were not ignored. If this value is equal to 0, it means that
        // user navigates to root ("/" or "<Drive>:\")
        int not_ignored_count = path_parts_buffer_size;

        // How many directories up is user moving by
        int ignores_left = 0;

        for (int part_index = path_parts_buffer_size - 1; part_index >= limit; --part_index)
        {
            split &part = path_parts[part_index];
            int number = get_up_count(part.str);

            if (number > -1)
            {
                ignores_left += number;
                not_ignored_count -= 1;
                part.to_print = false;
            }
            else if (ignores_left > 0)
            {
                --ignores_left;
                not_ignored_count -= 1;
                part.to_print = false;
            }
        }

        // It makes first path without unnecesary whitespace which would triggers linux
        if (first)
            first = false;
        else
            std::cout << ' ';

        if (not_ignored_count == 0) { std::cout << '/'; }
        else
        {
            for (int index = limit; index < path_parts_buffer_size; index++)
            {
                const split &part = path_parts[index];
                if (part.to_print) { std::cout << '/' << part.str; }
            }
        }
    }

    delete[] path_parts;

    // You can't delete not initialized pointer
    if (initialized) free(cwd);
}
