function get-srcs(){
    for dir in ${(@s/:/):-$SOURCE_DIR}; do
        for file in "$dir"/*; do
            print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-2]}
        done
    done
}
