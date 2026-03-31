function cd() {
    if [[ $1 == "-" ]]; then
        builtin cd -
    else
        builtin cd "$(expand-path $1)"
    fi
}


