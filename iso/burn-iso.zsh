function burn-iso(){
    if [[ $# -eq 0 ]]; then
        print "burn-iso <iso_path> <target_device> [<block_size=8M>]"
        return 1
    fi

    local iso_path=$1
    local target_drive=$2
    
    if [[ -z $3 ]]; then
        local block_size=$3
        "dd if=${$iso_path} of=${$target_drive} bs=${$block_size} status=progress"
    else
        "dd if=${$iso_path} of=${$target_drive} bs=8M sttaus=progress"
    fi
}
