function docker-composer() {
    local workdir="."
    local composer_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --working-dir|-d)
                workdir="$2"
                shift 2
                ;;
            *)
                composer_args+=("$1")
                shift
                ;;
        esac
    done

    abs_workdir="$(realpath "$workdir")"

    if [[ ! -f "$abs_workdir/composer.json" ]]; then
        echo "No composer.json found in $abs_workdir"
        return 1
    fi

    local container_path="/app/$workdir"

    docker run --rm -it \
        -v "$workdir:/app" \
        -w /app \
        "$DOCKER_PHP_IMAGE" \
        composer "${composer_args[@]}"
}

