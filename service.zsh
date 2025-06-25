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

function srv(){
    setopt local_options
    setopt extended_glob

    if (( ${@[(I)-h]} || ${@[(I)--help]} )); then
        print "Usage: srv <action> <service name>\n"
        print "\tcheck <[active | enabled]> <service name> - checks if service is running or enabled. Returns 1 for true and 0 for false\n"
        print "\tshow <service name> - shows info about service (alias for systemctl status)\n"
        print "\trun <service name> - starts service\n"
        print "\tstop <service name> - halts service\n"
        print "\trerun <service name> - restarts service\n"
        print "\tenable [-n | --now] <service name> - enables service. If service was enabled, informs about it\n"
        print "\tdisable [-n | --now] <service name> - disables service. If service was disabled, informs about it\n"
        print "\tlist <pattern> - lists all service unit files and their status. Alias for systemctl list-unit-files"
        return 0
    fi

    local action=$1
    local param=$2
    case $action in
        "check")
            srv-check ${@:2}
            ;;
        "show")
            systemctl status ${@:2}
            ;;
        "run")
            systemctl start $param
            ;;
        "stop")
            systemctl stop $param
            ;;
        "rerun")
            systemctl restart $param
            ;;
        "enable")
            if [[ $param == "-n" || $param == "--now" ]]; then
                local enabled=$(srv-check enabled $3)
                if [[ $enabled -eq 1 ]]; then
                    print "Service \"${3}\" was already enabled"
                else
                    systemctl enable $param $3
                fi
            else
                local enabled=$(srv-check enabled $2)
                if [[ $enabled -eq 1 ]]; then
                    print "Service \"${2}\" was already enabled"
                else
                    systemctl enable $2
                fi
            fi
            ;;
        "disable")
            if [[ $param == "-n" || $param == "--now" ]]; then
                if [[ $(srv-check enabled $3) -eq 0 ]]; then
                    print "Service \"${3}\" was already disabled"
                else
                    systemctl disable $param $3
                fi
            else
                if [[ $(srv-check enabled $2) -eq 0 ]]; then
                    print "Service \"${2}\" was already disabled"
                else
                    systemctl disable $2
                fi
            fi
            ;;
        "list")
            systemctl list-unit-files $param
            ;;
        *)
            print "Unknown action $1"
            ;;
    esac
}
print "Sourced service.zsh"
