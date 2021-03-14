#! /bin/bash

DATE=$(date +"%Y-%m-%d-%H-%M")
docker exec semawi-mysql /usr/bin/mysqldump -u root --password=root wiki > /srv/semawi/backup/$DATE.sql
