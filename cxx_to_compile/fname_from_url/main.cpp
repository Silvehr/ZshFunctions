#include "argv_matching.cpp"
#include <cstring>
#include <iostream>
#include <string_view>

using namespace std;
using namespace argv_matching;

int main(int argc, char **argv)
{
    auto args = get_program_args(argc, argv)[0].args;

    for (int index = 0; index < args.length; index++)
    {
        auto url = args[index];
        auto url_len = strlen(url);
        int url_index;
        bool found = false;
        for (url_index = url_len - 1; url_index > 0; url_index++)
        {
            if (url[url_index] == '/' && url[url_index - 1] != '\\')
            {
                found = true;
                break;
            }
        }

        if (!found && url[0] == '/')
        {
            found = true;
            url_index = 0;
        }

        std::cout << string_view(&url[url_index], url_len - url_index - 1);
    }
}
