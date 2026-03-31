HADES_ROOT_DIR="$HOME/.local/share/Steam/steamapps/common/Hades"

function install-hades-mod(){
    local mod_file=$1
    shift

    unzip $mod_file -d $HADES_ROOT_DIR/Content/Mods/
    local cwd="$(pwd)"
    cd $HADES_ROOT_DIR/Content
    $HADES_ROOT_DIR/Content/modimporter
    cd cwd
}
