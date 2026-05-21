function setup-docker-db(){
<<<<<<< HEAD
	local persistent=false
	if [[ $- == "p" ]]; then
		persistent=true
	fi
	local name=$1
	systemctl start docker
	if [[ $- == "p" ]]; then
		$(docker run --name "$name-db" -p 3306:3306 -d -v "$name:/var/lib/mysql" --env MARIADB_USER="$name" --env MARIADB_PASSWORD="$name" --env MARIADB_DATABASE="$name" --env MARIADB_ROOT_PASSWORD="$name" mariadb:11.4.10-ubi9 >> /dev/null)
		echo "Created container db with persistent data\nContainer name: $name"
	else
		$(docker run --name "$name-db" -p 3306:3306 -d --env MARIADB_USER="$name" --env MARIADB_PASSWORD="$name" --env MARIADB_DATABASE="$name" --env MARIADB_ROOT_PASSWORD="$name" mariadb:11.4.10-ubi9 >> /dev/null)
		echo "Temporaty data container\nContainer name: $name"
	fi

=======
    local name=$1

    systemctl start docker;
    local container_id=$(docker run \
        --detach \
        --name $name-db \
        -p 3306:3306 \
        --env MARIADB_USER=$name \
        --env MARIADB_PASSWORD=$name \
        --env MARIADB_DATABASE=$name \
        --env MARIADB_ROOT_PASSWORD=test \
        --volume $name-data:/var/lib/mysql \
        mariadb:11.4.10-ubi9);
    echo -n "Container name: $name-db"
>>>>>>> ec93398 (docker function)
}
