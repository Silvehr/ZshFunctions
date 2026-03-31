function mkcd() {
    while [[ $# -gt 1 ]]; do
        local current_arg=$@[1]
        local target_dir=$(expand-path "$current_arg")
        test -d "$target_dir"
        if [[ $? -eq 1 ]]; then
            mkdir -p "$target_dir" 2> /dev/null
            if [[ $? -eq 1 ]]; then
                print "Failed to create \"${target_dir}\""
            fi
        fi
        shift
    done

    local current_arg=$@[1]
    local target_dir=$(expand-path "$current_arg")

    local dir_exist=$(test -d "$target_dir"; echo $?)
    if [[ $dir_exist -eq 1 ]]; then
        mkdir -p "$target_dir" 2> /dev/null
        if [[ $? -eq 1 ]]; then
            print "Failed to create \"${target_dir}\""
        else
            dir_exist=0
        fi
    fi

    if [[ $dir_exist -eq 0 ]]; then
        builtin cd "$target_dir"
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
            local s=$1
            if [[ ${#s} -eq 0 ]]; then
                $EDITOR
            else
                $EDITOR "$(expand-path "$@")"
            fi
            ;;
    esac
}


