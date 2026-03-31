#include <cstring>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <utility>

namespace argv_matching
{
const char *POSITIONAL_NAME = "POSITIONAL";
const char *OTHER_NAME = "OTHER";

template <typename T> struct range
{
        int length;

    private:
        const T *data;

    public:
        range(const T *d, int len) : data(d), length(len) {}

        const T &operator[](const int index) const { return data[index]; }

        range &operator=(const range &other) noexcept
        {
            if (this == &other) return *this;

            std::exchange(data, other.data);
            std::exchange(length, other.length);
            return *this;
        }
};

enum class switch_arguments
{
    NONE = 0,
    SINGLE = 1,
    MULTIPLE = 2
};

struct program_switch
{

        const std::string short_switch;
        const std::string long_switch;
        const switch_arguments multiple_args;

        program_switch() : multiple_args(switch_arguments::NONE) {}

        program_switch(std::string &&short_switch, std::string &&long_switch, switch_arguments args)
            : short_switch(short_switch), long_switch(long_switch), multiple_args(multiple_args)
        {
        }

        [[nodiscard]] bool equals(const std::string_view &str) const
        {
            if (str.empty()) return false;

            std::string comp_str;
            if (str.length() == long_switch.length()) { comp_str = long_switch; }
            else if (str.length() == short_switch.length()) { comp_str = short_switch; }
            else
                return false;

            for (int index = 0; index < str.length(); index++)
            {
                if (str[index] != comp_str[index]) return false;
            }

            return true;
        }
};

struct p_arg
{
        const char *name;
        range<const char *> args;

        p_arg() : name(nullptr), args(range<const char *>(nullptr, 0)) {}
        p_arg(const char *n, range<const char *> args) : name(n), args(args) {}

        p_arg &operator=(const p_arg &other) noexcept
        {
            if (this == &other) return *this;

            std::exchange(name, other.name);
            std::exchange(args, other.args);
            return *this;
        }
};

struct program_args
{
        size_t length;

    private:
        p_arg *data;

    public:
        program_args(size_t len) : length(len), data(new p_arg[len]) {}

        const p_arg &operator[](const size_t index) const { return data[index]; }

        p_arg &at(const size_t index) { return data[index]; }

        int has(const program_switch &swt) const
        {
            for (size_t index = 0; index < length; index++)
            {
                if (data[index].name == nullptr) continue;

                if (swt.equals(std::string_view(data[index].name, strlen(data[index].name)))) return index;
            }

            return -1;
        }
};

program_args get_program_args(const int argc, char **argv)
{
    int arg_count = 0;
    bool switch_met = false;

    for (int index = 0; index < argc; index++)
    {
        if (argv[index][0] == '-')
        {
            switch_met = true;
            arg_count += 1;

            if (argv[index][1] == '-' && argv[index][2] == '\0') { break; }
        }
        else if (!switch_met)
        {
            arg_count += 1;
            switch_met += 1;
        }
    }

    program_args args(arg_count);
    switch_met = false;
    for (int index = 0, args_index = 0, arg_index = 0; index < argc; index++)
    {
        if (argv[index][0] == '-')
        {
            switch_met = true;
            int arg_index = index;
            index += 1;

            if (argv[arg_index][1] == '-' && argv[arg_index][2] == '\0')
            {
                while (index < argc)
                {
                    index += 1;
                }

                args.at(args_index) = p_arg(OTHER_NAME, range<const char *>(&OTHER_NAME, index - arg_index - 1));
                break;
            }
            else
            {
                while (index < argc && argv[index][0] != '-')
                {
                    index += 1;
                }

                args.at(args_index) =
                    p_arg(argv[arg_index], range<const char *>(&argv[arg_index + 1], index - arg_index - 1));

                index += 1;
            }
        }
        else if (!switch_met)
        {
            while (argv[++index][0] != '-')
                ;
            args.at(0) = p_arg(POSITIONAL_NAME, range<const char *>(argv, index));
            index -= 1;
        }
    }

    return args;
}
}; // namespace argv_matching
