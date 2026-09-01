function yt-dlp-mp4(){
    yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" $@ > /dev/null
}

function yt-dlp-mp3(){
    yt-dlp -x --audio-format mp3 --audio-quality 0 $@ > /dev/null
}
