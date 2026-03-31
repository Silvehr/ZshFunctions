#!/usr/bin/env zsh

if [[ $# -ne 1 ]]; then
    echo "Użycie: $0 plik.zsh"
    exit 1
fi

input="$1"
dir="$(dirname "$input")"

awk '
function flush() {
    if (fname != "") {
        file = dir "/" fname ".zsh"
        print buffer > file
        close(file)
    }
    buffer = ""
    fname = ""
}

/^[[:space:]]*(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_-]*[[:space:]]*\(\)[[:space:]]*\{/ {
    flush()
    match($0, /(function[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_-]*)/, m)
    fname = m[2]
}

{
    if (fname != "") {
        buffer = buffer $0 "\n"
    }
}

END {
    flush()
}
' dir="$dir" "$input"

