function docker-php() {
    local docroot=0
    local port=0

    local php_args=()
    local container_args=()

    local network="dev-net"
    local collecting_container_args=false

    while [[ $# -ne 0 ]]; do
        local arg="$1"

        if [[ "$collecting_container_args" == true ]]; then
            case "$arg" in
                -n)
                    shift
                    network="$1"
                    ;;
                --network)
                    shift
                    network="$1"
                    ;;
                *)
                    container_args+=("$arg")
                    ;;
            esac

            shift
            continue
        fi

        case "$arg" in
            --)
                collecting_container_args=true
                ;;

            # php -S ...
            -S)
                php_args+=("$arg")
                ;;

            # adres po -S
            *:*)
                php_args+=("$arg")
                port="${arg##*:}"
                ;;

            # php -t public
            -t)
                php_args+=("$arg")
                shift

                if [[ "$docroot" != 0 ]]; then
                    print "Cannot specify document root twice"
                    return 1
                fi

                docroot="$1"
                php_args+=("$1")
                ;;

            # opcje PHP
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

    if [[ "$docroot" == 0 ]]; then
        docroot="$(pwd)"
    fi

    if [[ "$port" == 0 ]]; then
        port="8000"
    fi

    print "Host document root: $docroot"
    print "Listening port: $port"
    print "Docker network: $network"

    docker run --rm -it \
        --network "$network" \
        -v "$docroot:/app" \
        -w /app \
        -p "$port:$port" \
        "${container_args[@]}" \
        "$DOCKER_PHP_IMAGE" \
        php "${php_args[@]}"
}
