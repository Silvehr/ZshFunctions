function nasm-bin-compile(){
    local file=$1
    local splitted=(${(@s:.:)file})
    local extension=$splitted[-1]
    if [[ $extension -ne 's' || $extension -ne 'as' || $extension -ne 'asm' ]]; then
        print "Not an assembly file"
        return 1
    fi

    local arch=$2
    splitted=$splitted[1,-2] # Without extension
    local fileName=${(j:.:)splitted}
    nasm -f elf -o "${fileName}.o" $file
    if [[ -f $fileName ]]
        rm $fileName
    ld -m "elf_${arch}" -o $fileName "${fileName}.o"
    rm "${fileName}.o"
}
