function rm(){
    while [[ $# -gt 0 ]]; do
        local target_path=$(expand-path "$1")
        /usr/bin/trash-put "$target_path" </dev/null
        local result=$?
        if [[ $result -ne 0 ]]; then
            if [[ -f $target_path ]]; then
                print "This file cannot be trashed..."
                read -q "choice?Want to use /usr/bin/rm instead? [y/n]: "
                print
                if [[ $choice != "y" ]]; then
                    print "Aborting..."
                    return 0
                else
                    print "Deleting file..."
                    /usr/bin/rm "$target_path"
                    if [[ $? -ne 0 ]]; then
                        print "This also failed... Aborting"
                        return $?
                    fi
                fi
            elif [[ -d $target_path ]]; then
                print "This directory cannot be trashed..."
                read -q "choice?Want to use /usr/bin/rm -rf instead? [y/n]: "
                print
                if [[ $choice != "y" ]]; then
                    print "Aborting..."
                    return 0
                else
                    print "Deleting file..."
                    /usr/bin/rm -rf "$target_path"
                    if [[ $? -ne 0 ]]; then
                        print "This also failed... Aborting"
                        return $?
                    fi
                fi
            else
                print "This item doesn't exist"
                return 1
            fi
        fi
        shift
    done
}

alias ni="touch"

