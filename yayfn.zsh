function rmpkgs(){
    while [[ $# -ne 0 ]]; do
        local pkgs=$(yay -Q | rg "$1" | awk '{print $1}')
        print "Packeges to remove:"
        for pkg in $pkgs; do
            print -n "${pkg} "
        done
        local ans=""

        while [[ 1 ]]; do
            print -n "\n\nDo you want these to be removed? [y/n]: "
            read -k ans
            print
            case $ans in
                y|Y)
                    for pkg in $pkgs; do
                        yay -Rnsc --noconfirm $pkg 2> /dev/null
                    done
                    break
                    ;;

                n|N)
                    print "Aborting removal of these packages..."
                    break
                    ;;
            esac
        done
        shift 
    done
}
