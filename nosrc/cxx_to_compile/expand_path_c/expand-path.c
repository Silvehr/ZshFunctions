#define _GNU_SOURCE
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct
{
        const char *str;
        int len;
} string_split;

typedef struct
{
        const char *str;
        int str_len;
        char splitter;
        int split_beg;
        int split_end;
        bool initialized;
} string_split_iterator;

string_split_iterator make_iterator(const char *str, int str_len, char splitter)
{
    string_split_iterator iter =
        {.str = str, .str_len = str_len, .splitter = splitter, .split_beg = 0, .split_end = 0, .initialized = false};
    return iter;
}

bool move_next(string_split_iterator *iter)
{
    if (!iter->initialized)
    {
        iter->split_end = -1;
        iter->split_beg = 0;
        iter->initialized = true;
    }

    if (iter->split_end == iter->str_len) return false;

beginning:
    iter->split_beg = iter->split_end + 1;
    iter->split_end = iter->split_beg;
    while (iter->split_end < iter->str_len)
    {
        if (iter->str[iter->split_end] == iter->splitter)
        {
            if (iter->split_end - iter->split_beg == 0) goto beginning;
            return true;
        }
        iter->split_end++;
    }
    return (iter->split_end - iter->split_beg) != 0;
}

string_split current(const string_split_iterator *iter)
{
    string_split split = {.str = &iter->str[iter->split_beg], .len = iter->split_end - iter->split_beg};
    return split;
}

bool try_convert(const char *str, int str_len, int *result)
{
    *result = 0;
    int index = 0;
    while (index != str_len)
    {
        int digit = (str[index] - 48);
        if (digit < 0 || digit > 9) return false;
        *result = *result * 10 + digit;
        index++;
    }
    return true;
}

int get_up_count(string_split split)
{
    const char *str = split.str;
    int length = split.len;

    if (length < 2) return -1;

    if (str[length - 1] == '\0') length -= 1;

    if (str[length - 1] != '.' || str[length - 2] != '.') return -1;

    if (length == 2) return 1;

    int result;
    if (!try_convert(str, length - 2, &result)) return -1;

    return result;
}

int main(int argc, char **argv)
{
    if (argc == 1)
    {
        char *tmp = get_current_dir_name();
        printf("%s\n", tmp);
        free(tmp);
        return 0;
    }

    char *cwd = NULL;
    int cwd_len = 0;
    bool initialized = false;

    bool absolute = argv[1][0] == '/';
    int total_path_part_count = 0 + !absolute;

    if (!absolute)
    {
        cwd = get_current_dir_name();
        cwd_len = strlen(cwd);
        initialized = true;

        for (int str_i = 0; str_i < cwd_len; ++str_i)
        {
            if (cwd[str_i] == '/') ++total_path_part_count;
        }
    }

    bool previous_character_was_separator = false;

    for (int argv_index = 1; argv_index < argc; argv_index++)
    {
        char *current_arg = argv[argv_index];
        int current_arg_len = strlen(current_arg);

        for (int str_i = 0; str_i < current_arg_len; ++str_i)
        {
            if (current_arg[str_i] == '/')
            {
                if (previous_character_was_separator) continue;
                previous_character_was_separator = true;
                ++total_path_part_count;
            }
            else { previous_character_was_separator = false; }
        }
    }

    string_split *path_part_array = malloc(total_path_part_count * sizeof(string_split));
    if (path_part_array == NULL)
    {
        perror("malloc failed");
        if (initialized) free(cwd);
        return 1;
    }

    int path_part_array_index = 0;

    if (!absolute)
    {
        string_split_iterator iter = make_iterator(cwd, cwd_len, '/');
        while (move_next(&iter))
        {
            path_part_array[path_part_array_index++] = current(&iter);
        }
    }

    for (int argv_index = 1; argv_index < argc; argv_index++)
    {
        char *current_arg = argv[argv_index];
        int arg_len = strlen(current_arg);

        string_split_iterator iter = make_iterator(current_arg, arg_len, '/');

        while (move_next(&iter))
        {
            string_split curr = current(&iter);
            int up_count = get_up_count(curr);
            if (up_count != -1)
            {
                path_part_array_index -= up_count;
                if (path_part_array_index < 0) path_part_array_index = 0;
            }
            else { path_part_array[path_part_array_index++] = curr; }
        }
    }

    if (path_part_array_index <= 0) { printf("/\n"); }
    else
    {
        for (int split_index = 0; split_index < path_part_array_index; split_index++)
        {
            printf("/%.*s", path_part_array[split_index].len, path_part_array[split_index].str);
        }
        putchar('\n');
    }

    free(path_part_array);

    if (initialized) free(cwd);
    return 0;
}
