IMAGE_NAME="EndeavourOS"
LOGO_TYPE="auto"
FF_ICON_DIR="${HOME}/Pictures/FastFetchIcons"
LOGO_HEIGHT=22
LOGO_WIDTH=50

case $TERM in
    *256color)
        IMAGE_EXTENSIONS=("txt")
        LOGO_TYPE="file"
        ;;
    *kitty)
        IMAGE_EXTENSIONS=("jpeg" "png" "jpg")
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

if [[ $TERM_PROGRAM != "vscode" ]]; then
    for extension in $IMAGE_EXTENSIONS; do
        file="${HOME}/Pictures/FastFetchIcons/${IMAGE_NAME}/${IMAGE_NAME}.${extension}"
        if [[ -f $file ]]; then
            fastfetch --${LOGO_TYPE} "${file}" --logo-height ${LOGO_HEIGHT} --logo-width ${LOGO_WIDTH}
            break
        fi
    done
fi
