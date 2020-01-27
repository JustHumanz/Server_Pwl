#/bin/bash
docker exec mariadb-web sh -c 'exec mysqldump --all-databases -uroot -p******' > /root/web_db.sql &
tar -zcvf /root/"$(date '+%Y-%m-%d').tar.gz" /usr/share/nginx/html/ /root/web_db.sql 
exit 0
