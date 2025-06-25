function invoke(){
    local output=1
    local error=1
    local exit_code=1
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                case $2 in
                    "true"|"1") output=1 ;;
                    "false"|"0") output=0 ;;
                esac
                shift
                ;;
            "-c"|--exit-code)
                case $2 in
                    "true"|"1") exit_code=1 ;;
                    "false"|"0") exit_code=0 ;;
                esac
                shift
                ;;
            "-e"|--error)
                case $2 in
                    "true"|"1") error=1 ;;
                    "false"|"0") error=0 ;;
                esac
                shift
                ;;
            "--")
                shift
                local to_append=""
                if [[ $output -eq 0 ]]; then
                    to_append="${to_append} > /dev/null"
                fi
                if [[ $error -eq 0 ]]; then
                    to_append="${to_append} 2> /dev/null"
                fi
                eval "$@$to_append"
                if [[ $exit_code -eq 1 ]]; then
                    echo $?
                fi
                return 0
                ;;
        esac
        shift
    done
}

function sudo-fn() {
    local usage="Usage: sudo-fn [-b] [-n] [-a] [-p program] function_name [more_functions...] [-- args...]"
    local background=0
    local no_password=0
    local include_aliases=0
    local sudo_program="sudo"

    local fn_list=()
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            # run as background job
            -b) background=1 ;;

            # no password
            -n) no_password=1 ;;

            # pass aliases
            -a) include_aliases=1 ;;

            # check if user wants to change sudo program to doas or any other wrapper
            -p)
                shift
                if [[ -z "$1" ]]; then
                    echo "Error: -p requires a program name." >&2
                    return 2
                fi
                sudo_program="$1"
                ;;
            --) 
                shift 
                args=("$@") 
                break 
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "$usage" >&2
                return 2
                ;;
            *)
                # check if function exists by generating errors
                if declare -f "$1" >/dev/null; then
                    fn_list+=("$1")
                else
                    echo "Function '$1' not found." >&2
                    return 2
                fi
                ;;
        esac
        shift
    done

    if [[ ${#fn_list[@]} -eq 0 ]]; then
        echo "No function names provided." >&2
        echo "$usage" >&2
        return 2
    fi
    
    local defs=""
    for fn in "${fn_list[@]}"; do
        defs+=$(declare -f "$fn")
        defs+=$'\n'
    done

    if (( $include_aliases )); then
        defs+="\n$(alias -p)"
    fi

    local sudo_opts=()
    (( no_password )) && sudo_opts+=("-n")

    local com="$defs; ${fn_list[1]} ${(@q)args}"

    if (( $background )); then
        com+=" &"
    fi

    "$sudo_program" "${sudo_opts[@]}" "$SHELL" -c "$com"
    return $?
}
print "Sourced invoking.zsh"
