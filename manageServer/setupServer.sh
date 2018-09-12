#!/bin/bash
if [ `whoami` != "root" ]; then
	echo "Script must be executed as root"
	exit 1
fi
TITLE='[35m'
INPUT='[32m'
RESET='[0m'

echo -e "\e${TITLE} -=Setup Generic PHP server=- \e${RESET}"
echo -e "\e${TITLE} --System Prep \e${RESET}"
echo -e "\e${TITLE} -Adding Repos \e${RESET}"
#legacy php
add-apt-repository ppa:ondrej/php -y

#for mongo
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

echo -e "\e${TITLE} -Configue vagrant for SSH \e${RESET}"
cp -f /sv/manageServer/setupAssets/ssh/github_key /home/vagrant/github_key
chmod 600 /home/vagrant/github_key
cp -f /sv/manageServer/setupAssets/ssh/ssh_config /home/vagrant/.ssh/config
chmod 600 /home/vagrant/.ssh/config
chown vagrant:vagrant -R /home/vagrant

echo -e "\e${TITLE} --Update Ubuntu \e${RESET}"
apt-get update -y

echo -e "\e${TITLE} --Install Server Components \e${RESET}"


echo -e "\e${TITLE} -Install Apache \e${RESET}"
apt install apache2 -y

echo -e "\e${TITLE} -Configure Apache \e${RESET}"
#config files based on linode update to match the server values when possible
cp -f /sv/manageServer/setupAssets/apache/apache2.conf /etc/apache2/apache2.conf
cp -f /sv/manageServer/setupAssets/apache/mpm_prefork.conf  /etc/apache2/mods-available/mpm_prefork.conf
cp -f /sv/manageServer/setupAssets/apache/mime.types /etc/mime.types
cp -f /sv/manageServer/setupAssets/apache/server.crt /etc/ssl/certs/server.crt
cp -f /sv/manageServer/setupAssets/apache/server.key /etc/ssl/private/server.key


#enable prefork
a2dismod mpm_event
a2enmod mpm_prefork

#enable ssl
a2enmod ssl

#enable htaccess
a2enmod rewrite

#enable proxyPass
a2enmod proxy_http

#build log directories
mkdir -p /sv/logs
mkdir -p /sv/webroot
mkdir -p /sv/webroot/www
chown www-data /sv/logs

#load generic config
cp -f /sv/manageServer/setupAssets/apache/generic.com.conf /etc/apache2/sites-available/generic.com.conf
#disable default
a2dissite 000-default.conf
#enable generic
a2ensite generic.com.conf

echo -e "\e${TITLE} -Install MySQL \e${RESET}"
apt install mysql-server -y

echo -e "\e${TITLE} -Configure MySQL \e${RESET}"
#build generic local database
#build test database
mysql --user=root mysql <<EOF
update user set authentication_string=PASSWORD('pass123') where user='root';
flush privileges;
CREATE DATABASE webdata;
GRANT ALL ON webdata.* TO 'webuser' IDENTIFIED BY 'password';
quit
EOF

echo -e "\e${TITLE} -Restart MySQL \e${RESET}"
service mysql restart


echo -e "\e${TITLE} -Install PHP 5.6 \e${RESET}"

apt install php5.6 libapache2-mod-php5.6 php5.6-mysql php5.6-curl php5.6-json php5.6-cgi php5.6-xml php5.6-xmlrpc php5.6-cli php-pear php5.6-dev php5.6-mongo -y

cp -f /sv/manageServer/setupAssets/php/php.ini /etc/php/5.6/apache2/php.ini 
cp -f /sv/manageServer/setupAssets/php/index.php /sv/webroot/www/index.php 

echo -e "\e${TITLE} -Install Mongo \e${RESET}"
apt-get install -y autoconf g++ make openssl libssl-dev libcurl4-openssl-dev pkg-config libsasl2-dev libpcre3-dev
pecl install mongo

#local mongo for future use
apt-get install -y mongodb-org

echo -e "\e${TITLE} -Restart Apache \e${RESET}"
systemctl restart apache2

echo -e "\e${TITLE} -=End Setup=- \e${RESET}"