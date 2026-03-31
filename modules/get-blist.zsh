function get-blist() {
    cat /etc/modprobe.d/blacklist | awk '{if($1=="blacklist"){print $2}}'
}
