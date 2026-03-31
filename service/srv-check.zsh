local function srv-check(){
    case $1 in
        active)
            local state=$(systemctl is-active $2)
            if [[ $state == "active" ]]; then
                echo 1
            else
                echo 0
            fi
            ;;
        enabled)
            local state=$(systemctl is-enabled $2)
            if [[ $state == "enabled" ]]; then
                echo 1
            else
                echo 0
            fi
            ;;
        *)
            print "Unknown action ${1}"
            return 1
            ;;
    esac
}
