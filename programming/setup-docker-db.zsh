function setup-docker-db(){
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
}
