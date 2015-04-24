#!/bin/bash

if [ $(id -u) != "0" ]; then
    printf "Error, you can login user root!\n"
    exit
fi

if [ -f /var/cpanel/cpanel.config ]; then
echo "Server is install WHM/Cpanel, if you want using aisheeblog"
echo "Please install rebuild Centos 7"
echo "Good bye"
exit
fi

if [ -f /etc/psa/.psa.shadow ]; then
echo "Server is install Plesk, if you want using script aisheeblog"
echo "Please install rebuild Centos 7"
echo "Good bye"
exit
fi

if [ -f /etc/init.d/directadmin ]; then
echo "Server is install DirectAdmin, if you want script aisheeblog"
echo "Please install rebuild Centos 7"
echo "Good bye"
exit
fi

if [ -f /etc/init.d/webmin ]; then
echo "Server is install webmin, if you want script aisheeblog"
echo "Please install rebuild Centos 7"
echo "Good bye"
exit
fi

if [ -f /etc/aisheeblog/scripts.conf ]; then
echo "Server is install script aisheeblog"
echo "Good bye"
exit
fi

#Info
aisheeblog_version="1.0"
pma_version="4.2.10"
url_aisheeblog="http://aisheeblog.com"

yum -y install gawk bc
wget -q $url_aisheeblog/calc -O /bin/calc && chmod +x /bin/calc

clear
printf "=========================================================================\n"
printf "Testing parameter of server \n"
printf "=========================================================================\n"

cpuname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpucores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpufreq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
svram=$( free -m | awk 'NR==2 {print $2}' )
svhdd=$( df -h | awk 'NR==2 {print $2}' )
svswap=$( free -m | awk 'NR==4 {print $2}' )

if [ -f "/proc/user_beancounters" ]; then
svip=$(ifconfig venet0:0 | grep 'inet addr:' | awk -F'inet addr:' '{ print $2}' | awk '{ print $1}')
else
svip=$(ifconfig eth0 | grep 'inet addr:\|inet' | awk -F'inet addr:|inet ' '{ print $2}' | awk '{ print $1}')
fi


printf "=========================================================================\n"
printf "Infomation of Server \n"
printf "=========================================================================\n"
echo "CPU : $cpuname"
echo "CPU core : $cpucores"
echo "Speed Core : $cpufreq MHz"
echo "RAM : $svram MB"
echo "Swap : $svswap MB"
echo "Disk : $svhdd GB"
echo "IP : $svip"
printf "=========================================================================\n"
printf "=========================================================================\n"
sleep 3


clear
printf "=========================================================================\n"
printf "Are you ready??... \n"
printf "=========================================================================\n"

printf "Enter for php php version:\n"
prompt="Input [1-3]: "
options=("PHP 5.6" "PHP 5.5" "PHP 5.4")
PS3="$prompt"
select opt in "${options[@]}"; do 

    case "$REPLY" in
    1) php_version="5.6"; break;;
    2) php_version="5.5"; break;;
    3) php_version="5.4"; break;;
    $(( ${#options[@]}+1 )) ) printf "\nGood bye....!\n"; break;;
    *) echo "Input error, please again";continue;;
    esac
    
done

echo -n "Input the Domain [ENTER]: " 
read aishee_domain
if [ "$aishee_domain" = "" ]; then
	aishee_domain="aisheeblog.com"
echo "Input error, domain default is aisheeblog.com"
fi

echo -n "Input port for PhpMyAdmin [ENTER]: " 
read aishee_port
if [ "$aishee_port" = "" ] || [ "$aishee_port" = "80" ] || [ "$aishee_port" = "443" ] || [ "$aishee_port" = "22" ] || [ "$aishee_port" = "3306" ] || [ "$aishee_port" = "25" ] || [ "$aishee_port" = "465" ] || [ "$aishee_port" = "587" ]; then
	aishee_port="2313"
echo "Script default port: 2313"
fi

echo -n "Input email [ENTER]: " 
read umail
if [ "$umail" = "" ]; then
	umail="info@$aishee_domain"
echo "Input error, email default is info@$aishee_domain"
fi

printf "=========================================================================\n"
printf "Successful... \n"
printf "=========================================================================\n"


rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

#Remi Repo
yum -y install epel-release
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

#Nginx Repo
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

systemctl stop  sendmail.service
systemctl disable sendmail.service
systemctl stop  xinetd.service
systemctl disable xinetd.service
systemctl stop  saslauthd.service
systemctl disable saslauthd.service
systemctl stop  rsyslog.service
systemctl disable rsyslog.service
systemctl stop  postfix.service
systemctl disable postfix.service

yum -y remove mysql*
yum -y remove php*
yum -y remove httpd*
yum -y remove sendmail*
yum -y remove postfix*
yum -y remove rsyslog*

yum -y update

clear
printf "=========================================================================\n"
printf "Start setup.... \n"
printf "=========================================================================\n"
sleep 3

#Install Nginx, PHP-FPM and modules
if [ "$php_version" = "5.6" ]; then
	yum -y --enablerepo=remi,remi-php56 install nginx php-fpm php-common php-gd php-mysql php-pdo php-xml php-mbstring php-mcrypt php-curl unzip nano
elif [ "$php_version" = "5.5" ]; then
	yum -y --enablerepo=remi,remi-php55 install nginx php-fpm php-common php-gd php-mysql php-pdo php-xml php-mbstring php-mcrypt php-curl unzip nano
else
	yum -y --enablerepo=remi install nginx php-fpm php-common php-gd php-mysql php-pdo php-xml php-mbstring php-mcrypt php-curl unzip nano
fi

#Install MariaDB
yum -y install mariadb-server mariadb exim syslog-ng cronie

clear
printf "=========================================================================\n"
printf "Start conguration... \n"
printf "=========================================================================\n"
sleep 3


ramformariadb=$(calc $svram/10*6)
ramforphpnginx=$(calc $svram-$ramformariadb)
max_children=$(calc $ramforphpnginx/30)
memory_limit=$(calc $ramforphpnginx/5*3)M
buff_size=$(calc $ramformariadb/10*8)M
log_size=$(calc $ramformariadb/10*2)M

systemctl start  exim.service
systemctl start  syslog-ng.service

#Set programs autostart
systemctl enable nginx.service
systemctl enable php-fpm.service
systemctl enable mariadb.service


mkdir -p /home/$aishee_domain/public_html
mkdir /home/$aishee_domain/private_html
mkdir /home/$aishee_domain/logs
chmod 777 /home/$aishee_domain/logs


mkdir -p /var/log/nginx
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /var/lib/php/session

wget -q $url_aisheeblog/html/index.html -O /home/$aishee_domain/public_html/index.html

rm -f /etc/nginx/nginx.conf
    cat > "/etc/nginx/nginx.conf" <<END

user  nginx;
worker_processes  $cpucores;
worker_rlimit_nofile 65536;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
	worker_connections  2048;
}


http {
	include       /etc/nginx/mime.types;
	default_type  application/octet-stream;

	log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	              '\$status \$body_bytes_sent "\$http_referer" '
	              '"\$http_user_agent" "\$http_x_forwarded_for"';

	access_log  off;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay off;
	types_hash_max_size 2048;
	server_tokens off;
	server_names_hash_bucket_size 128;
	client_max_body_size 20m;
	client_body_buffer_size 256k;
	client_body_in_file_only off;
	client_body_timeout 60s;
	client_header_buffer_size 256k;
	client_header_timeout  20s;
	large_client_header_buffers 8 256k;
	keepalive_timeout 10;
	keepalive_disable msie6;
	reset_timedout_connection on;
	send_timeout 60s;
	gzip on;
	gzip_static on;
	gzip_disable "msie6";
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_types text/plain text/css application/json text/javascript application/javascript text/xml application/xml application/xml+rss;

	include /etc/nginx/conf.d/*.conf;
}
END

rm -rf /etc/nginx/conf.d
mkdir -p /etc/nginx/conf.d

aishee_domain_redirect="www.$aishee_domain"
if [[ $aishee_domain == *www* ]]; then
    aishee_domain_redirect=${aishee_domain/www./''}
fi

cat > "/usr/share/nginx/html/403.html" <<END
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>aisheeblog-nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/usr/share/nginx/html/404.html" <<END
<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>404 Not Found</h1></center>
<hr><center>aisheeblog-nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/etc/nginx/conf.d/$aishee_domain.conf" <<END
server {
	server_name $aishee_domain_redirect;
	rewrite ^(.*) http://$aishee_domain\$1 permanent;
    	}
server {
	listen   80 default_server;
		
	access_log off;
	error_log off;
    	# error_log /home/$aishee_domain/logs/error.log;
    	root /home/$aishee_domain/public_html;
	index index.php index.html index.htm;
    	server_name $aishee_domain;
 
    	location / {
		try_files \$uri \$uri/ /index.php?\$args;
	}
 
    	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	include /etc/nginx/fastcgi_params;
        	fastcgi_pass 127.0.0.1:9000;
        	fastcgi_index index.php;
		fastcgi_connect_timeout 60;
		fastcgi_send_timeout 180;
		fastcgi_read_timeout 180;
		fastcgi_buffer_size 256k;
		fastcgi_buffers 4 256k;
		fastcgi_busy_buffers_size 256k;
		fastcgi_temp_file_write_size 256k;
		fastcgi_intercept_errors on;
        	fastcgi_param SCRIPT_FILENAME /home/$aishee_domain/public_html\$fastcgi_script_name;
    	}
	location /nginx_status {
  		stub_status on;
  		access_log   off;
	}
	location /php_status {
		fastcgi_pass 127.0.0.1:9000;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME  /home/$aishee_domain/public_html\$fastcgi_script_name;
		include /etc/nginx/fastcgi_params;
    	}
	location ~ /\. {
		deny all;
	}
        location = /favicon.ico {
                log_not_found off;
                access_log off;
        }
       location = /robots.txt {
              allow all;
              log_not_found off;
              access_log off;
       }
	location ~* \.(3gp|gif|jpg|jpeg|png|ico|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso|eot|svg|ttf|woff)$ {
	        gzip_static off;
		add_header Pragma public;
		add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		access_log off;
		expires 30d;
		break;
        }

        location ~* \.(txt|js|css)$ {
	        add_header Pragma public;
		add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		access_log off;
		expires 30d;
		break;
        }
	
        #error_page 403 /403.html;
        location = /403.html {
                root /usr/share/nginx/html;
                allow all;
        }
	
        #error_page 404 /404.html;
        location = /404.html {
                root /usr/share/nginx/html;
                allow all;
        }
    }

server {
	listen   $aishee_port;
 	access_log        off;
	log_not_found     off;
 	error_log         off;
    	root /home/$aishee_domain/private_html;
	index index.php index.html index.htm;
    	server_name $aishee_domain;
 
     	location / {
		try_files \$uri \$uri/ /index.php;
	}
    	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	include /etc/nginx/fastcgi_params;
        	fastcgi_pass 127.0.0.1:9000;
        	fastcgi_index index.php;
		fastcgi_connect_timeout 60;
		fastcgi_send_timeout 180;
		fastcgi_read_timeout 180;
		fastcgi_buffer_size 256k;
		fastcgi_buffers 4 256k;
		fastcgi_busy_buffers_size 256k;
		fastcgi_temp_file_write_size 256k;
		fastcgi_intercept_errors on;
        	fastcgi_param SCRIPT_FILENAME /home/$aishee_domain/private_html\$fastcgi_script_name;
    	}
        location ~* \.(bak|back|bk)$ {
		deny all;
	}
}
END


rm -f /etc/php-fpm.d/www.conf
    cat > "/etc/php-fpm.d/www.conf" <<END
[www]
listen = 127.0.0.1:9000
listen.allowed_clients = 127.0.0.1
user = nginx
group = nginx
pm = dynamic
pm.max_children = $max_children
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 6
pm.max_requests = 500 
pm.status_path = /php_status
request_terminate_timeout = 120s
request_slowlog_timeout = 4s
slowlog = /home/$aishee_domain/logs/php-fpm-slow.log
rlimit_files = 131072
rlimit_core = unlimited
catch_workers_output = yes
env[HOSTNAME] = \$HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
php_admin_value[error_log] = /home/$aishee_domain/logs/php-fpm-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php/session
END


rm -f /etc/php.ini
    cat > "/etc/php.ini" <<END
[PHP]
engine = On
short_open_tag = Off
asp_tags = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions = escapeshellarg,escapeshellcmd,exec,ini_alter,parse_ini_file,passthru,pcntl_exec,popen,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,show_source,shell_exec,symlink,system
disable_classes =
zend.enable_gc = On
expose_php = On
max_execution_time = 30
max_input_time = 60
memory_limit = $memory_limit
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 180M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
cgi.fix_pathinfo=0
file_uploads = On
upload_max_filesize = 200M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
cli_server.color = On

[Date]
date.timezone = Asia/Bangkok

[filter]

[iconv]

[intl]

[sqlite]

[sqlite3]

[Pcre]

[Pdo]

[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=

[Phar]

[mail function]
SMTP = localhost
smtp_port = 25
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On

[SQL]
sql.safe_mode = Off

[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1

[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"

[MySQL]
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off

[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off

[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off

[OCI8]

[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0

[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10

[bcmath]
bcmath.scale = 0

[browscap]

[Session]
session.save_handler = files
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.bug_compat_42 = Off
session.bug_compat_warn = Off
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"

[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatability_mode = Off

[Assertion]

[mbstring]

[gd]

[exif]

[Tidy]
tidy.clean_output = Off

[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5

[sysvshm]

[ldap]
ldap.max_links = -1

[mcrypt]

[dba]

END

rm -f /etc/php-fpm.conf
    cat > "/etc/php-fpm.conf" <<END
include=/etc/php-fpm.d/*.conf

[global]
pid = /var/run/php-fpm/php-fpm.pid
error_log = /home/$aishee_domain/logs/php-fpm.log
emergency_restart_threshold = 10
emergency_restart_interval = 60s
process_control_timeout = 10s
daemonize = yes
END

rm -f /etc/my.cnf.d/server.cnf
    cat > "/etc/my.cnf.d/server.cnf" <<END
[server]

[mysqld]
skip-host-cache
skip-name-resolve
collation-server = utf8_unicode_ci
init-connect='SET NAMES utf8'
character-set-server = utf8
skip-character-set-client-handshake

user = mysql
default_storage_engine = InnoDB
socket = /var/lib/mysql/mysql.sock
pid_file = /var/lib/mysql/mysql.pid

key_buffer_size = 32M
myisam_recover = FORCE,BACKUP
max_allowed_packet = 16M
max_connect_errors = 1000000
datadir = /var/lib/mysql/
tmp_table_size = 32M
max_heap_table_size = 32M
query_cache_type = ON
query_cache_size = 2M
long_query_time = 5
max_connections = 5000
thread_cache_size = 50
open_files_limit = 65536
table_definition_cache = 1024
table_open_cache = 1024
innodb_flush_method = O_DIRECT
innodb_log_files_in_group = 2
innodb_log_file_size = $log_size
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table = 1
innodb_buffer_pool_size = $buff_size

log_error = /home/$aishee_domain/logs/mysql.log
log_queries_not_using_indexes = 0
slow_query_log = 1
slow_query_log_file = /home/$aishee_domain/logs/mysql-slow.log

[embedded]

[mysqld-5.5]

[mariadb]

[mariadb-5.5]
END


    cat >> "/etc/security/limits.conf" <<END
* soft nofile 65536
* hard nofile 65536
nginx soft nofile 65536
nginx hard nofile 65536
END

ulimit  -n 65536

mkdir -p /etc/aisheeblog/menu
mkdir -p /etc/aisheeblog/update

rm -f /etc/aisheeblog/scripts.conf
    cat > "/etc/aisheeblog/scripts.conf" <<END
mainsite="$aishee_domain"
priport="$aishee_port"
email="$umail"
serverip="$svip"
aisheeblog_version="$aisheeblog_version"
url_aisheeblog="$url_aisheeblog"
END


rm -f /var/lib/mysql/ib_logfile0
rm -f /var/lib/mysql/ib_logfile1
rm -f /var/lib/mysql/ibdata1


rm -f /bin/mysql_secure_installation
wget -q $url_aisheeblog/mysql_secure_installation -O /bin/mysql_secure_installation && chmod +x /bin/mysql_secure_installation
clear
printf "=========================================================================\n"
printf "Conguration MariaDB ... \n"
printf "=========================================================================\n"
systemctl start mariadb.service

/bin/mysql_secure_installation

systemctl restart mariadb.service

clear
printf "=========================================================================\n"
printf "Conguration Successful... \n"
printf "=========================================================================\n"
cd /home/$aishee_domain/private_html/
wget -q http://jaist.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/$pma_version/phpMyAdmin-$pma_version-english.zip
unzip -q phpMyAdmin-$pma_version-english.zip
mv -f phpMyAdmin-$pma_version-english/* .
rm -rf phpMyAdmin-$pma_version-english

#Disable firewalld and install iptables
yum -y install iptables-services
systemctl mask firewalld
systemctl enable iptables
systemctl enable ip6tables
systemctl stop firewalld
systemctl start iptables
systemctl start ip6tables

if [ -f /etc/sysconfig/iptables ]; then
systemctl start  iptables.service
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp --dport 25 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 465 -j ACCEPT
iptables -I INPUT -p tcp --dport 587 -j ACCEPT
iptables -I INPUT -p tcp --dport $aishee_port -j ACCEPT
service iptables save
fi

mkdir -p /var/lib/php/session
chown -R nginx:nginx /var/lib/php

rm -f /root/install

clear
printf "=========================================================================\n"
printf "Autostart add menu aisheeblog... \n"
printf "=========================================================================\n"

wget -q $url_aisheeblog/aisheeblog -O /bin/aisheeblog && chmod +x /bin/aisheeblog
wget -q $url_aisheeblog/uvs/turn-off-phpmyadmin -O /etc/aisheeblog/menu/turn-off-phpmyadmin && chmod +x /etc/aisheeblog/menu/turn-off-phpmyadmin
wget -q $url_aisheeblog/uvs/backup-code -O /etc/aisheeblog/menu/backup-code && chmod +x /etc/aisheeblog/menu/backup-code
wget -q $url_aisheeblog/uvs/backup-data -O /etc/aisheeblog/menu/backup-data && chmod +x /etc/aisheeblog/menu/backup-data
wget -q $url_aisheeblog/uvs/create-database -O /etc/aisheeblog/menu/create-database && chmod +x /etc/aisheeblog/menu/create-database
wget -q $url_aisheeblog/uvs/turn-off-auto-backup -O /etc/aisheeblog/menu/turn-off-auto-backup && chmod +x /etc/aisheeblog/menu/turn-off-auto-backup
wget -q $url_aisheeblog/uvs/add-website -O /etc/aisheeblog/menu/add-website && chmod +x /etc/aisheeblog/menu/add-website
wget -q $url_aisheeblog/uvs/auto-backup -O /etc/aisheeblog/menu/auto-backup && chmod +x /etc/aisheeblog/menu/auto-backup
wget -q $url_aisheeblog/uvs/delete-database -O /etc/aisheeblog/menu/delete-database && chmod +x /etc/aisheeblog/menu/delete-database
wget -q $url_aisheeblog/uvs/delete-website -O /etc/aisheeblog/menu/delete-website && chmod +x /etc/aisheeblog/menu/delete-website
wget -q $url_aisheeblog/uvs/park-domain -O /etc/aisheeblog/menu/park-domain && chmod +x /etc/aisheeblog/menu/park-domain
wget -q $url_aisheeblog/uvs/redirect-domain -O /etc/aisheeblog/menu/redirect-domain && chmod +x /etc/aisheeblog/menu/redirect-domain
wget -q $url_aisheeblog/uvs/upgrade-server -O /etc/aisheeblog/menu/upgrade-server && chmod +x /etc/aisheeblog/menu/upgrade-server
wget -q $url_aisheeblog/uvs/list-website -O /etc/aisheeblog/menu/list-website && chmod +x /etc/aisheeblog/menu/list-website
wget -q $url_aisheeblog/uvs/change-pass -O /etc/aisheeblog/menu/change-pass && chmod +x /etc/aisheeblog/menu/change-pass
wget -q $url_aisheeblog/uvs/chmod-webserver -O /etc/aisheeblog/menu/chmod-webserver && chmod +x /etc/aisheeblog/menu/chmod-webserver
chmod +x /etc/aisheeblog/menu/*


    cat > "/tmp/sendmail.sh" <<END
#!/bin/bash

echo -e 'Subject: Setup Successful!\nHello you!\n\nWebsite: http://$aishee_domain/\nLink phpMyAdmin: http://$aishee_domain:$aishee_port/ (or http://$svip:$aishee_port/)\nUpload source : /home/$aishee_domain/public_html/\n\nManager server enter command "aisheeblog".\n\nThanks you for using script aisheeblog \n\naisheeblog.Com !' | exim  $umail
END
chmod +x /tmp/sendmail.sh
/tmp/sendmail.sh
rm -f /tmp/sendmail.sh

clear
printf "=========================================================================\n"
printf "Scripts aisheeblog setup successful... \n"
printf "=========================================================================\n"
printf "Infomation Server\n\n"
printf "Website: http://$aishee_domain/ (or http://$svip/) \nLink phpMyAdmin: http://$aishee_domain:$aishee_port/ (or http://$svip:$aishee_port/) \nUpload source code: /home/$aishee_domain/public_html/\n"
printf "=========================================================================\n"
printf "Manager server enter command \"aisheeblog\".\n"
printf "Website serverupport: http://aisheeblog.com\n"
printf "=========================================================================\n"
printf "Server reboot.... \n\n"
sleep 3
reboot
exit
