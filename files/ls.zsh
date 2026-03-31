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
            colorls --sd -L -1 "${options[@]}" "$(expand-path "$arg")"
            ;;
    esac
}


