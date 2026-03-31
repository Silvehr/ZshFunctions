function php-setup(){
    if [ $# -eq 0 ]; then
        print "You have to pass startup file name"
        return 1
    fi

    local startup_file=$1
    sudo cp -r . /srv/http
    echo "<?php\n\tinclude \"${startup_file}\";\n?>" | sudo tee /srv/http/index.php > /dev/null
    sudo systemctl restart httpd
}

