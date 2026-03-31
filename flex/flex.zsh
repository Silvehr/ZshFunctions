IMAGE_EXTENSIONS=(".")
IMAGE_NAME="EndeavourOS"
LOGO_TYPE="auto"

LOGO_HEIGHT=22
LOGO_WIDTH=50

case $TERM in
    *256color)
        IMAGE_EXTENSIONS=("txt")
        LOGO_TYPE="file"
        ;;
    *kitty)
        IMAGE_EXTENSIONS=("jpeg" "png")
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

on-source(){
    fastfetch
}

alias ffd="ff C_Sharp"
