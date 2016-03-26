#!/bin/bash

# Ruan Bekker <ruan@ruanbekker.com>
# Info:
# MailServer with VirtualUsers + MySQL + PostfixAdmin + Amavisd + Spamassassin
# tag: mail1

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
rpm --import http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt

cd /tmp
rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm

yum install epel-release -y
yum install yum-priorities -y
yum update -y
yum groupinstall 'Development Tools' -y
yum remove sendmail exim -y

yum install perl-CPAN perl-YAML postfix ntp httpd httpd-devel mod_ssl mod_python mysql-server php php-mysql php-imap php-mbstring phpmyadmin dovecot dovecot-mysql -y
yum install openssl amavisd-new spamassassin clamav clamd unzip bzip2 unrar perl-DBD-mysql -y
yum install php php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-mssql php-snmp php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel perl-DateTime-Format-HTTP perl-DateTime-Format-Builder -y

/etc/init.d/dovecot start
/etc/init.d/mysqld start
/etc/init.d/sendmail stop
/etc/init.d/postfix restart
/etc/init.d/httpd restart

chkconfig --levels 235 mysqld on
chkconfig --levels 235 postfix on
chkconfig --levels 235 httpd on
chkconfig --levels 235 dovecot on
chkconfig --levels 235 amavisd on
chkconfig --del clamd
chkconfig --levels 235 clamd.amavisd on

sa-update
/usr/bin/freshclam
/etc/init.d/amavisd start
/etc/init.d/clamd.amavisd start

sed -i 's/;error_reporting = E_ALL & ~E_DEPRECATED/error_reporting = E_ALL & ~E_NOTICE/' /etc/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/' /etc/php.ini

/etc/init.d/httpd restart

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/postfix/smtpd.key -out /etc/postfix/smtpd.cert

cd /tmp/
wget http://repo.ruanbekker.com/packages/postfixadmin-2.3.6.tar.gz
tar -xvf postfixadmin-2.3.6.tar.gz
cd /tmp/postfixadmin-2.3.6
mv * /var/www/html/

cd /tmp/
wget -O /tmp/postfix.sql http://repo.ruanbekker.com/configs/postfix-clds3.sql
mkdir /etc/postfix/mysql/ -p
cd /etc/postfix/mysql

wget http://repo.ruanbekker.com/configs/mysql_transport_maps.cf
wget http://repo.ruanbekker.com/configs/mysql_virtual_alias_maps.cf
wget http://repo.ruanbekker.com/configs/mysql_virtual_domains_maps.cf
wget http://repo.ruanbekker.com/configs/mysql_virtual_mailbox_limit_maps.cf
wget http://repo.ruanbekker.com/configs/mysql_virtual_mailbox_maps.cf
wget http://repo.ruanbekker.com/configs/mysql_transport_maps.cf


chown mysql:mysql /etc/postfix/mysql_*
cd /etc/postfix/

mv main.cf maincf_old
wget -O /etc/postfix/main.cf http://repo.ruanbekker.com/configs/main-clds3.cf
echo "127.0.0.1" > /etc/postfix/mynetwors

cd /etc/dovecot/
mv dovecot.conf original-dovecot
wget -O /etc/dovecot/dovecot.conf http://repo.ruanbekker.com/configs/dovecot-clds3.conf
wget -O /etc/dovecot/dovecot-sql.conf http://repo.ruanbekker.com/configs/dovecot-sql-clds3.conf

mkdir /var/spool/virtual -p
useradd vmail -r -u 5000 -g mail -d /var/spool/virtual -s /sbin/nologin
groupadd vmail -g 50001
chmod -R 777 /var/spool/virtual
chown -R vmail:vmail /var/spool/virtual

mysql -u root -p < /tmp/postfix.sql

service dovecot restart
service postfix restart
service httpd restart

echo "configure /var/www/html/config.inc.php"

