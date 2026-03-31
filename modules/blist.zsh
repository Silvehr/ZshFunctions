function blist() {
    if [[ $UID != 0 ]]; then
        print "You need to be root to execute this command"
        return 1
    fi

    local blacklistFile="/etc/modprobe.d/blacklist"
    local module="$1"

    if [[ -z "$module" ]]; then
        print "Usage: blist <module_name>"
        return 2
    fi

    if [[ ! -f "$blacklistFile" ]]; then
        touch "$blacklistFile" || {
            echo "Failed to create $blacklistFile"
            return 3
        }
    fi

    if grep -q "^blacklist[[:space:]]\+$module\$" "$blacklistFile"; then
        print "Module \"$module\" is already blacklisted."
    else
        print "blacklist $module" >>"$blacklistFile" || {
            echo "Failed to write to $blacklistFile"
            return 4
        }
        print "Module \"$module\" has been blacklisted."
    fi
}


