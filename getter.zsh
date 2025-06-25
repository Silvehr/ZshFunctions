function format-nic-info()
{
    local iface=$1
    # MAC
    mac=$(ip link show dev "$iface" | awk '/ether/ {print $2}')
    [[ -z "$mac" ]] && mac="%F{red}(none)%f"

    # IPv4
    ipv4=$(ip -o -4 addr show dev "$iface" | awk '{print $4}' | paste -sd ',' -)
    [[ -z "$ipv4" ]] && ipv4="%F{red}(none)%f"

    # IPv6
    ipv6=$(ip -o -6 addr show dev "$iface" | awk '$4 !~ /^fe80/ {print $4}' | paste -sd ',' -)
    [[ -z "$ipv6" ]] && ipv6="%F{red}(none)%f"

    print -P "%F{red}$iface%f :\n\t%F{blue}IPv4:%f $ipv4\n\t%F{green}IPv6:%f $ipv6\n\t%F{yellow}MAC:%f $mac"
}

function get()
{
    local target=$1
    shift

    case $target in
        ip|nic)
            local iface mac ipv4 ipv6
            if [[ $# -eq 0 ]]; then
                for iface in ${(f)"$(ip -o link show | awk -F': ' '{print $2}')"}; do
                    format-nic-info $iface
                done
            else
                setopt localoptions extended_glob
                while [[ $# -ne 0 ]]; do
                    local arg=$1
                    local pattern="${1:-*}"
                    local len=${#arg}

                    for iface in ${(f)"$(ip -o link show | awk -F': ' '{print $2}')"}; do
                        if [[ $len == "0" || "$iface" == *$pattern* ]]; then
                            format-nic-info $iface
                        fi
                    done
                    shift
                done
            fi
            ;;

        shell)
            local action=$1
            if [[ -z $action ]]; then
                print $SHELL
            fi
            case $action in
                version|v)
                    $SHELL --version
                    ;;
                name|n)
                    basename $SHELL
                    ;;
                srcs)
                for dir in ${(@s/:/):-$SOURCE_DIR}; do
                    for file in "$dir"/*; do
                        print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-2]}
                    done
                done
                ;;
            esac
            ;;
        term)
            echo $TERM
            ;;
        srv)
            local target=$1
            systemctl status ${target}
            ;;
        srcs)
            for dir in ${(@s/:/):-$SOURCE_DIR}; do
                for file in "$dir"/*; do
                    print ${(@j:.:)${(@s:.:)${(s:/:)file}[-1]}[1,-2]}
                done
            done
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
