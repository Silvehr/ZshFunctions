
function get()
{
    local target=$1
    shift

    case $target in
        ip|nic)
            ;;

        term)
            echo $TERM
            ;;

        profiles)
            for file in /etc/profile.d/*; do
                print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-1]}
            done
            ;;
        nvim-plugins)
            for file in $HOME/.config/nvim/lua/plugins/*; do
                print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-2]}
            done
            ;;
    esac
}
