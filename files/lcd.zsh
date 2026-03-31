function lcd(){
    local target=$1

    if [[ $# -eq 0 ]]; then
        target="."
    fi

    if [[ $target == "-" ]]; then
        builtin cd -
    else
        builtin cd "$(expand-path $1)"
    fi

    local options=("${@[1,-2]}")
    local arg="${@[-1]}"

    ls .
}


