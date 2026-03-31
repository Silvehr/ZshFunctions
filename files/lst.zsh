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
        colorls --tree="$depth" ${options[@]} $(expand-path $arg)
    else
        colorls --tree ${options[@]} $(expand-path $arg)
    fi
}


