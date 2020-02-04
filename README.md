# <p align="center"> <b> PWL Server config  </b> </p>  


#### <p align="center"> Server specification </p>  
OS  : CentOS 7  
IP Public : 1  
RAM : 1GB  
CPU : 1 Core  
Shell : Zsh  
![neofetch](https://raw.githubusercontent.com/JustHumanz/Server_Pwl/master/img/neofetch.png)  

#### <p align="center"> Penjelasan </p>  
Diserver ini saya menggunakkan Nginx sebagai reverse proxy dan httpd(apache) sebagai backendnya dikarenakan nginx kurang begitu bagus untuk menghandle dynamic file seperti php,jika ingin melihat pembahasannya bisa [disini](https://justhumanz.me/index.php/2019/11/09/nginx-as-a-reverse-proxy-for-httpd/).  

![reverse-proxy](https://www.unixhops.com/wp-content/uploads/2015/03/apache-nginx-reverse-proxy-diagram.jpg)  
disini saya hanya menjelaskan config yang saya anggap penting saja,tidak menjelaskan cara installasi dan config dasar     

### Nginx conf
```
gzip                on;
gzip_static         on;
gzip_vary           on;
gzip_comp_level     6;
gzip_min_length     1024;
gzip_buffers        16 8k;
gzip_types          text/plain text/css text/javascript text/js text/xml application/json application/javascript application/x-javascript application/xml application/xml+rss application/x-font-ttf image/svg+xml font/opentype;
gzip_proxied        any;
gzip_disable        "MSIE [1-6]\.";
```  
menyalakan gzip compression yang berfungsi untuk mengkompres file tertentu agar pengirimannya menjadi lebih ringan tetapi disisi lain memperberat kerja CPU karena harus mengkompres file tersebut sebelum dikirim ke client maka dari itu tidak semua file saya kompres hanya beberapa saja bisa dilihat di gzip_types  
![testing-gzip](https://raw.githubusercontent.com/JustHumanz/Server_Pwl/master/img/gzip.png)  
  
```
proxy_redirect      off;
proxy_set_header    Host            $host;
proxy_set_header    X-Real-IP       $remote_addr;
proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_pass_header   Set-Cookie;
proxy_buffers       32 4k;
proxy_connect_timeout   30s;
proxy_send_timeout  90s;
proxy_read_timeout  90s;
```  
setting proxynya agar bisa diterima oleh apache(backend),disini saya meneruskan informasi ip client ke apache lalu proxy timeoutnya 90 detik  

#### Nginx virtualhost conf
```
listen    80;
server_name 165.22.243.195;
```
melisten atau berjalan di port 80 dengan servernamenya 165.22.243.195 dikarenakan tidak ada domainnya  
```
location / {
    proxy_pass      http://localhost:8080;
    proxy_no_cache $no_cache;
    proxy_cache_bypass $no_cache;
    proxy_cache_bypass $cookie_session $http_x_update;

    location ~* ^.+\.(jpg|jpeg|gif|png|ico|svg|css|zip|tgz|gz|rar|bz2|doc|xls|exe|pdf|ppt|txt|odt|ods|odp|odf|tar|wav|bmp|rtf|js|mp3|avi|mpeg|flv|html|htm)$ {
        proxy_cache    off;
        root           /usr/share/nginx/html/;
        try_files      $uri @fallback;
    }

    
 }
```
proxy_pass itu maksudnya semua requst akan dikirim ke http://localhost:8080 (apache) dan disini tugas nginx hanya sebagai reverse proxy dengan tambahan mengkompres file yang akan dikirim  
```
location ~ /\.ht    {return 404;}
location ~ /\.svn/  {return 404;}
location ~ /\.git/  {return 404;}
location ~ /\.hg/   {return 404;}
location ~ /\.bzr/  {return 404;}
```
terakhir adalah file .ht .git .svn .hg .bzr yang ada diserver akan tidak bisa dikases oleh public dengan kode error 404,itu dikarenakan alasan security ya bisa dibilang folder .(dot) git,htaccess adalah file/foler yang bersifat rahasa dan tidak boleh diketahui oleh public  

### Httpd(apache) conf  
hampir config default tambahannya cuman server-status untuk monitoring via grafana
```
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from 127.0.0.1
</Location>
```  
#### Httpd(apache) virtualhost conf
```
Listen 8080
<VirtualHost *:8080>
    ServerAdmin humanz@justhumanz.me
    DocumentRoot /usr/share/nginx/html/
    ServerName 165.22.243.195

  <Directory /usr/share/nginx/html/>
    Require all granted
    AllowOverride All
  </Directory>
</VirtualHost>
```
settingan default,tidak ada yang spesial

### Mysql(Mariadb)
dikarenakan saya dan paji ingin coba coba dan tidak mau ribet maka diputuskan bahwa untuk mysql kita menggunakan docker saja
```
docker run --name mariadb-web -v /opt/mysql/:/var/lib/mariadb -e MYSQL_ROOT_PASSWORD=***** -d -p 3306:3306 mariadb
```
volume storage kita bind ke /opt/mysql/ dikarenakan jika container terhapus maka data didalamnya ikut terhapus  

### Script auto backup
backup adalah hal yang sangat sangat penting dari sebuah system dan saya males ssh cuman buat backup saja maka dari itu saya membuat script awto backup system untuk pencegahan jika terjadi hal hal yang mengancam keselamatan data
```
#/bin/bash
docker exec mariadb-web sh -c 'exec mysqldump --all-databases -uroot -p******' > /root/web_db.sql &
tar -zcvf /root/"$(date '+%Y-%m-%d').tar.gz" /usr/share/nginx/html/ /root/web_db.sql 
exit 0
```
pertama tama adalah membackup mysql yang ada didocker dan ditempatkan di /root/ kemudian membuat file compress yang berisi backup mysql dan seluruh folder /html/ yang berisi web aplikasi kelas lalu ditempatkan di /root/,saya tempatkan di /root/ karena file backup adalah file yang penting sekaligus berbahaya jika diambil orang lain maka dari itu saya tempatkan file tersebut di /root/

#### Crontab job
terakhir adalah pengeksekusi script backup secara berkala,disini saya setting setiap jam 1 dini hari
```
1 0 * * * /opt/backup/autobackup.sh >/dev/null 2>&1
```

