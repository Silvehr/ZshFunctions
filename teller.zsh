TELL_ME_WHY_USAGE_COUNT=0
function tell(){
    local to_who=$1
    shift

    case $to_who in
        me|Me|mE|ME)
            local what=${@[1]:l}
            case $what in
                why)
                    case $TELL_ME_WHY_USAGE_COUNT in
                        "0")
                            print "... Ain\'t nothin\' but a heartache"
                            ;;
                        "1")
                            print "... Ain\'t nothin\' but a mistake"
                            ;;
                        "2")
                            print ".. I never wanna hear you say"
                            print "I want it that way"
                            TELL_ME_WHY_USAGE_COUNT=$((-1))
                            ;;
                    esac
                    TELL_ME_WHY_USAGE_COUNT=$((TELL_ME_WHY_USAGE_COUNT+1))
                    ;;
            esac
            ;;
        *)
            ;;
    esac
}
