function docker-php() {
    local docroot=0
    local port=0

    local php_args=()

    while [[ $# -ne 0 ]]; do
        local arg=$1
        case "$arg" in

            # php -S ...
            -S)
                php_args+=("$arg")
                ;;

            # adres po -S
            *:* )
                php_args+=("$arg")
                port="${arg##*:}"
                ;;

            # php -t public
            -t)
                php_args+=("$arg")
                shift
                if [[ $docroot != 0 ]]; then
                    print "Cannot specify document root twice"
                    return 1
                fi
                docroot=$1 
                ;;

            # opcje
            -*)
                php_args+=("$arg")
                ;;

            # pliki/ścieżki
            *)
                if [[ "$arg" = /* ]]; then
                    php_args+=("$arg")
                else
                    php_args+=("/app/$arg")
                fi
                ;;
        esac
        shift
    done

    if [[ $docroot == 0 ]]; then
        docroot="$(pwd)"
    fi

    if [[ $port == 0 ]]; then
        port="8000"
    fi

    print "Host document root: $docroot"
    print "Listening port: "

    docker run --rm -it \
        -v "$docroot:/app/" \
        -w /app \
        -p $port:$port \
        "$DOCKER_PHP_IMAGE" \
        php "${php_args[@]}"
}
