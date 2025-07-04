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

function lcd(){
    local target=$1

    if [[ $# -eq 0 ]]; then
        target="."
    fi

    if [[ $target == "-" ]]; then
        builtin cd -
    else
        builtin cd "$(expand $1)"
    fi

    local options=("${@[1,-2]}")
    local arg="${@[-1]}"

    ls .
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

function rm(){
    local path=$1
    path="$(/usr/bin/expand $path)"
    /usr/bin/trash-put $path
    local result=$?
    if [[ $result -ne 0 ]]; then
        if [[ -f $path ]]; then
            print "This file cannot be trashed..."
            read -q "choice?Want to use /usr/bin/rm instead? [y/n]: "
            print
            if [[ $choice != "y" ]]; then
                print "Aborting..."
                return 0
            else
                print "Deleting file..."
                /usr/bin/rm $path
                if [[ $? -ne 0 ]]; then
                    print "This also failed... Aborting"
                    return $?
                fi
            fi
        elif [[ -d $path ]]; then
            print "This directory cannot be trashed..."
            read -q "choice?Want to use /usr/bin/rm -rf instead? [y/n]: "
            print
            if [[ $choice != "y" ]]; then
                print "Aborting..."
                return 0
            else
                print "Deleting file..."
                /usr/bin/rm -rf $1
                if [[ $? -ne 0 ]]; then
                    print "This also failed... Aborting"
                    return $?
                fi
            fi
        else
            print "This item doesn't exist"
            return -1
        fi
    fi
}

alias ni="touch"
