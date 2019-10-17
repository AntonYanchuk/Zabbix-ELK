#!/bin/bash

#zpasswd=zabbix

if [ "$(hostname)" = zabbix-server ]
then

sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm

sudo yum clean all


sudo yum install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-get zabbix-sender zabbix-agent postgresql-server vim htop  postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql



#sudo -u postgres createuser zabbix
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD 'zabbix'";
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/doc/zabbix-server-pgsql-4.4.0/create.sql.gz | sudo -u zabbix psql zabbix


#sudo mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.old

#cat <<EOF > /etc/zabbix/zabbix_server.conf
#LogFile=/var/log/zabbix/zabbix_server.log
#LogFileSize=0
##DebugLevel=1
#PidFile=/var/run/zabbix/zabbix_server.pid
#SocketDir=/var/run/zabbix
#DBHost=127.0.0.1
#DBSchema=zabbix
#DBName=zabbix
#DBUser=zabbix
#DBPassword=zabbix
#DBPort=5432
#SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
#Timeout=4
#AlertScriptsPath=/usr/lib/zabbix/alertscripts
#ExternalScripts=/usr/lib/zabbix/externalscripts
#LogSlowQueries=3000
#StatsAllowedIP=127.0.0.1



#EOF
#chown -R root:zabbix /etc/zabbix/zabbix_server.conf

cat > /var/lib/pgsql/data/pg_hba.conf  <<HBA
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    zabbix          zabbix          127.0.0.1/32            password
local   all             all                                     peer
host    all             all             ::1/128                 md5
HBA

sudo sed -i 's/#\ php_value date.timezone\ Europe\/Riga/php_value date.timezone Europe\/Minsk/g' /etc/httpd/conf.d/zabbix.conf 
#sudo chown -R zabbix:zabbix /etc/zabbix/



sudo sed -i 's/#\ DBPassword=/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/#\ DBHost=localhost/DBHost=127.0.0.1/' /etc/zabbix/zabbix_server.conf

cat <<EOF > /etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'POSTGRESQL';
\$DB['SERVER']   = '127.0.0.1';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = 'zabbix';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF
sudo chown apache:apache /etc/zabbix/web/zabbix.conf.php
#sudo sed 's/#\ php_value date.timezone\ Europe\/Riga/php_value date.timezone Europe\/Minsk/g' /etc/httpd/conf.d/zabbix.conf 
# php_value date.timezone Europe/Riga
#sudo chown -R apache:apache /etc/zabbix/web/

#sudo sed -i 's/Alias\ \/zabbix/Alias\ \//'  /etc/httpd/conf.d/zabbix.conf
cat <<EOF > /etc/httpd/conf.d/zabbix.conf
<VirtualHost *:80>
DocumentRoot /usr/share/zabbix
ServerName 192.168.56.141

  <Directory "/usr/share/zabbix">
    Options FollowSymLinks
    AllowOverride None
    Require all granted

    <IfModule mod_php5.c>
      php_value max_execution_time 300
      php_value memory_limit 128M
      php_value post_max_size 16M
      php_value upload_max_filesize 2M
      php_value max_input_time 300
      php_value always_populate_raw_post_data -1
      php_value date.timezone America/Toronto
    </IfModule>
  </Directory>

  <Directory "/usr/share/zabbix/conf">
    Require all denied
  </Directory>

  <Directory "/usr/share/zabbix/app">
    Require all denied
  </Directory>

  <Directory "/usr/share/zabbix/include">
    Require all denied
  </Directory>

  <Directory "/usr/share/zabbix/local">
    Require all denied
  </Directory>
</VirtualHost>
EOF

sudo systemctl restart zabbix-server zabbix-agent httpd postgresql
sudo systemctl enable zabbix-server zabbix-agent httpd postgresql

else

sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm

sudo yum clean all

sudo yum install -y zabbix-agent vim

sudo sed -i 's/127.0.0.1/192.168.56.141/g' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's/Hostname=Zabbix\ server/Hostname=zagent/g' /etc/zabbix/zabbix_agentd.conf
#Hostname=Zabbix server
#127.0.0.1
sudo systemctl enable zabbix-agent
sudo systemctl enable zabbix-agent



fi