
function src() {
    local root="$USER_PROFILE_ROOT"
    local shell="${SHELL:t}"

    if (( $# == 0 )) || [[ $1 == rc ]]; then
        source-all --no-onsource "$root"
        return
    fi

    local targets=()
    local not_found=()

    for query in "$@"; do
        local dir="."
        local name="$query"

        # obsługa folder/plik
        if [[ $query == */* ]]; then
            dir="${query%/*}"
            name="${query##*/}"
        fi

        local matches=(
            ${(@f)$(fd --hidden --type f "^${name}\.${shell}$" "$root/$dir")}
        )

        if (( ${#matches} == 0 )); then
            not_found+=("$query")
        else
            targets+=("${matches[@]}")
        fi
    done

    if (( ${#not_found} )); then
        print -u2 "Not found: ${(j:,:)not_found}"
        return 1
    fi

    # jeżeli wiele plików – fzf
    if (( ${#targets} > 1 )) && command -v fzf >/dev/null; then
        targets=(
            ${(f)"$(print -l $targets | fzf --multi --prompt='source > ')"} 
        )
    fi

    for file in "${targets[@]}"; do
        print "→ sourcing $file"
        source "$file"
    done
}
