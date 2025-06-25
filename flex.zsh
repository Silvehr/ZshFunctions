ICON_DIR_NAME="."
LOGO_TYPE="auto"
FF_ICON_DIR="/usr/share/icons/FastFetch"

LOGO_HEIGHT=25
LOGO_WIDTH=50

case $TERM in
    *256color)
        ICON_DIR_NAME="txt"
        LOGO_TYPE="file"
        ;;
    *kitty)
        ICON_DIR_NAME="jpeg"
        LOGO_TYPE="kitty"
        ;;
esac

function find-ff-icon(){
    if [[ $# -eq 1 ]]; then
        fd $1 $FF_ICON_DIR
    else
        fd $2 "${FF_ICON_DIR}/${1}"
    fi
}

function ff()
{
    fastfetch --${LOGO_TYPE} "$(find-ff-icon ${ICON_DIR_NAME} ${1})" --logo-height ${LOGO_HEIGHT} --logo-width ${LOGO_WIDTH}
}

alias ffd="ff C_Sharp"
