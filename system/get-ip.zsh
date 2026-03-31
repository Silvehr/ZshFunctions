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

function get-ip()
{
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
}
