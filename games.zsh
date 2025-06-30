HADES_ROOT_DIR="$HOME/.local/share/Steam/steamapps/common/Hades"

function install-mod(){
    local target_game=$1
    shift
    local mod_file=$1
    shift

    case $target_game in
        hades)
            unzip $mod_file -d $HADES_ROOT_DIR/Content/Mods/
            local cwd="$(pwd)"
            cd $HADES_ROOT_DIR/Content
            $HADES_ROOT_DIR/Content/modimporter
            cd cwd
            ;;
    esac
}
