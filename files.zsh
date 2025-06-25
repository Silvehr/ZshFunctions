function get-source(){
    get-file $@ ${(@s/:/):-$SOURCE_DIR}
}

function get-file(){
    with_extension=false
    debug=false
    while [[ $# -ne 0 ]]; do
        case $1 in
            -e|--extension)
                with_extension=true
                ;;
            -d|--debug)
                debug=true
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    searched_file=$1
    shift
    for dir in $@; do
        [[ $debug == true ]] && print "Examined directory: ${dir}"
        for file in "$dir"/*; do
            local base=${file:t}

            [[ $debug == true ]] && print "\tExamined file: ${base} with ${searched_file}"
            if [[ $with_extension == true ]]; then
                if [[ $base == $searched_file ]]; then
                    print $file
                    return 0
                fi
            else
                local file_name=${base:r}
                if [[ $file_name == $searched_file ]]; then
                    print $file
                    return 0
                fi
            fi
        done
    done
    print "Source file not found."
    return 1
}

function try-get-source(){
    local file=$(get-source $@)
    if [[ $? -ne 0 ]]; then
        file=$(get-source -e $@)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    print $file
    return 0
}

function ls() {
    if [[ $# -eq 0 ]]; then
        colorls --sd -L -1 .
        return
    fi

    local options=("${@[1,-2]}")
    local arg="${@[-1]}"

    case $arg in
        -*)
            colorls --sd -L -1 "${options[@]}" "${arg}" "."
            ;;
        *)
            colorls --sd -L -1 "${options[@]}" "$(expand "$arg")"
            ;;
    esac
}

function lst() {
    if [[ $# -eq 0 ]]; then
        colorls --tree .
        return 0
    fi
    
    if [[ ${@[-1]} == -* ]]; then
        local options=$@
        local use_depth=false
        local arg="."
    else
        local numre='^[0-9]+$'
        if [[ ${@[-2]} =~ $numre ]]; then
            local use_depth=true
            local options=${@[1,-3]}
            local depth=${@[-2]}
        else
            local use_depth=false
            local options=${@[1,-2]}
        fi
        local arg=${@[-1]}
    fi

    if [[ $use_depth = true ]]; then
        colorls --tree="$depth" ${options[@]} $(expand $arg)
    else
        colorls --tree ${options[@]} $(expand $arg)
    fi
}

function cd() {
    if [[ $1 == "-" ]]; then
        builtin cd -
    else
        builtin cd "$(expand $1)"
    fi
}

function mkcd() {
    local lastArg=$@[-1]
    local targetDir=$(expand $lastArg)
    local dirMade=false

    if [[ ! -d "$targetDir" ]]; then
        mkdir -p "$targetDir"
        if [[ $? -eq 0 ]]; then
            dirMade=true
        fi
    else
        dirMade=true
    fi

    if [[ $dirMade == true ]]; then
        builtin cd "$targetDir"
    fi
}

function edit()
{
    case $1 in
        "rc")
            $EDITOR "${HOME}/.$(basename $SHELL)rc" 
            ;;
        "src")
            file=$(try-get-source $2)
            if [[ $? -ne 0 ]]; then 
                print "Source file not found"
                return 1
            fi
            $EDITOR $file 
            ;;
        "init")
            if [[ -f ./init ]]; then
                $EDITOR ./init
            else
                $EDITOR "${HOME}/.config/nvim/init.lua"
            fi
            ;;
        *)
            $EDITOR $(expand $1)
            ;;
    esac
}

function list() {
    case $1 in
        srcs)
            for dir in ${(@s/:/):-$SOURCE_DIR}; do
                for file in "$dir"/*; do
                    print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-2]}
                done
            done
            ;;
        profile.d)
            for file in /etc/profile.d/*; do
                print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-1]}
            done
            ;;
        nvim-plugins)
            for file in $HOME/.config/nvim/lua/plugins/*; do
                print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-2]}
            done
            ;;
    esac
}

function src() {
    if [[ $# -eq 0 ]]; then
        source $HOME/.$(basename $SHELL)rc
        return 0
    fi
    case $1 in
        "rc")
            source $HOME/.$(basename $SHELL)rc
            ;;
        "src")
            local file=$(try-get-source $2)
            if [[ $? -ne 0 ]]; then 
                print "Source file not found"
                return 1
            fi
            source $file
            ;;
        "env")
            if [[ -f "env" ]]; then
                source $env
            else
                source /etc/environment
            fi
            ;;
        profile)
            if [[ -f "profile" ]]; then
                source "profile"
            else
                source /etc/profile
            fi
            ;;
        profile.d)
            source /etc/profile.d/$2
            ;;
        *)
            shift
            source $@
            ;;
    esac
}


# function rm(){
#     setopt extendedglob
#     local require_confirm=true
#     local warn_on_dotfiles=false
#     local use_regex=false
#     local safe_regex=false
#     local targets=()
#     local regex_patterns=()
#     local safe_regex_patterns=()
#     local target_count=0
#     while [[ $# -ne 0 ]]; do
#         local arg=$1
#         case $1 in
#             -h|--help)
#                 print "rm [options] <files/directories>"
#                 print "Delete file or directory"
#                 print "\t-y --no-confirm             :           Do not ask for confirmation for deleting non-empty directory"
#                 print "\t-d --warn-on-dotfiles       :           Ask for confirmation for files that begins with dot"
#                 print "\t-r --regex <patterns>       :           Use regex patterns for searching. If you want to use regex and strict names you should specify strict names first"
#                 print "\t                                        like this: rm <strict names> [-r|--regex] <regex patterns>"
#                 print "\t-sr --safe-regex <patterns> :           Everybody can make mistakes, ask foreach file that should be deleted using these regexes. IT DOES NOT WORK ON REGEXES USED IN --regex" 
#                 print "\t                                        You may choose to give answer once for other deletions"
#                 print "\t-h --help                   :           Display this message"
#                 ;;
#                 return 0
#             -y|--no-confirm)
#                 require_confirm=false 
#                 ;;
#             -d|--warn-on-dotfiles)
#                 warn_on_dotfiles=true
#                 ;;
#             -r|--regex)
#                 shift 
#                 while [[ ! $1 == -* ]]; do
#                     regex_patterns+=($1)
#                     shift
#                 done
#                 use_regex=true
#                 ;;
#             -sr|--safe-regex)
#                 use_regex=true
#                 safe_regex=true
#                 ;;
#             -*)
#                 print "\x1b[38;2;255;0;0mUnknown option \'$1\'"
#                 return 1
#                 ;;
#             *)
#                 targets+=($arg)
#                 target_count=$((target_count+1))
#                 ;;
#         esac
#         shift
#     done
#
#     for target in $targets; do
#         if [[ -d $target ]]; then
#             if [[ -z ${(f)"${target}/*(N)"} ]]; then
#                 rmdir $target
#             elif [[ $require_confirm == true ]]; then
#                 print -n "Directory is not empty. Do you want to proceed? [Y/n][n]: "
#                 read -k 1 answer
#                 print
#                 case $answer in
#                     [Yy])
#                         /usr/bin/rm -rf -- "$target"
#                         ;;
#                     [Nn]|"")
#                         print "Directory \'$target\' has not been deleted"
#                         ;;
#                 esac
#             else
#                 /usr/bin/rm -rf -- "${target}"
#             fi
#         elif [[ ! -f $target ]]; then
#             print "\x1b[38;2;255;0;0mFile \'$target\' doesn't exist"
#             return 1
#         elif [[ ${target[1]} == "." && $warn_on_dotfiles == true ]]; then
#             print -n "File is dotfile. Do you want to proceed? [Y/n][n]: "
#             read -k 1 answer
#             print
#             case $answer in
#                 [Yy])
#                     /usr/bin/rm -f -- "$target"
#                     ;;
#                 [Nn]|"")
#                     print "File \'$target\' has not been deleted"
#                     ;;
#             esac
#         else
#             /usr/bin/rm "${target}"
#         fi
#     done
# }

alias rm="trash"

alias ni="touch"
