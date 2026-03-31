function rm-tmp-db(){
	docker kill $1
	docker rm $1
}
