#!/bin/bash

# ================================ #
#  Mail Server with:               #
#  - Spamassassin, Amavis, ClamAv  #
#  - VirtualUsers, MySQL           #
#  - MailAdmin                     #
#                                  #
#  Tested on:                      #
#  - Debian Jessie                 #
# ================================ #

echo "Enter Fully Qualified Domain Name:"
read get_fqdn

set_host=`echo $get_fqdn | cut -d'.' -f1`
set_domain=`echo $get_fqdn | cut -d'.' -f2,3,4,5,6`
set_fqdn=`echo $get_fqdn`

cat > /etc/hosts << EOF
127.0.0.1 $set_fqdn $set_host localhost.localdomain localhost
EOF

echo "$set_host" > /etc/hostname
/etc/init.d/hostname.sh

export DEBIAN_FRONTEND="noninteractive"

# UPDATES:
cat > /etc/apt/sources.list << EOF2
deb http://httpredir.debian.org/debian          jessie         main
deb http://security.debian.org/ jessie/updates main
deb-src http://security.debian.org/ jessie/updates main contrib non-free
deb http://ftp.us.debian.org/debian/ jessie main contrib non-free
deb-src http://ftp.us.debian.org/debian/ jessie main contrib non-free
deb http://httpredir.debian.org/debian jessie-updates main contrib non-free
deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free
EOF2

apt-get update && apt-get upgrade -y
apt-get install --reinstall systemd dbus -y
apt-get install apt-utils telnet -y 
apt-get install ca-certificates -y
update-ca-certificates
apt-get install build-essential debconf-utils mailutils -y
apt-get install libsqlite3-dev zlib1g-dev libncurses5-dev libgdbm-dev libbz2-dev  libssl-dev libdb-dev -y
apt-get install syslog-ng ssh openssh-server wget curl tcpdump netcat vim gnupg2 mutt -y 
apt-get install apache2 apache2-dev -y
apt-get install python -y
apt-get install python-setuptools -y

gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

# VARIABLES:
export DOMAIN="$set_domain"
export EMAIL=admin@"$DOMAIN"
export EMAILPASS=$(openssl rand -hex 4)
export MAILDB="mailserver"
export MAILDBUSER="mailuser"
export MAILDBPASS=$(openssl rand -hex 4)
export HOST="$set_host"
export FQDN="$set_fqdn"

# Updates
apt-get update && apt-get upgrade -y

debconf-set-selections <<< "postfix postfix/mailname string $FQDN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# set password for mysql
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MAILDBPASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MAILDBPASS"
debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password password $MAILDBPASS"
debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password_again password $MAILDBPASS"

service sendmail stop
apt-get remove sendmail -y
apt-get install openssl postfix postfix-mysql -y
apt-get install php5 php-pear php5-mysql -y
apt-get install php5-mcrypt php5-intl -y

apt-get install swaks -y
apt-get install mysql-server mysql-client ruby-mysql -y
apt-get install libmysqlclient-dev -y
apt-get install dovecot-mysql dovecot-pop3d dovecot-imapd dovecot-managesieved -y

mkdir /etc/ssl/certs /etc/ssl/private -p

openssl genrsa -des3 -passout pass:$EMAILPASS -out /etc/ssl/private/$FQDN.key 2048
chmod 0600 /etc/ssl/private/$FQDN.key
openssl req -new -key /etc/ssl/private/$FQDN.key -out /root/$FQDN.csr -passin pass:$EMAILPASS -subj "/C=ZA/ST=CapeTown/O=Tech/OU=Hosting/CN=$DOMAIN"
openssl x509 -req -days 365 -in /root/$FQDN.csr -signkey /etc/ssl/private/$FQDN.key -out /etc/ssl/certs/$FQDN.crt -passin pass:$EMAILPASS
openssl rsa -in /etc/ssl/private/$FQDN.key -out /etc/ssl/private/$FQDN.nopass.key -passin pass:$EMAILPASS
chmod 0600 /etc/ssl/private/$FQDN.nopass.key
openssl req -new -x509 -extensions v3_ca -keyout /etc/ssl/private/cakey.pem -out /etc/ssl/certs/cacert.pem -days 3650 -passout pass:$EMAILPASS -subj "/C=ZA/ST=CapeTown/O=Tech/OU=Hosting/CN=$DOMAIN"
chmod 0600 /etc/ssl/private/cakey.pem
mv /etc/ssl/private/$FQDN.nopass.key /etc/ssl/private/$FQDN.key

cat > ~/mailserver.sql << EOF3
CREATE DATABASE $MAILDB;
GRANT ALL ON $MAILDB.* TO '$MAILDBUSER'@'127.0.0.1' IDENTIFIED BY "$MAILDBPASS";
use $MAILDB;
FLUSH PRIVILEGES;

CREATE TABLE \`virtual_domains\` ( 
\`id\` int(11) NOT NULL auto_increment, 
\`name\` varchar(50) NOT NULL, 
PRIMARY KEY (\`id\`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
CREATE TABLE \`virtual_users\` (
\`id\` int(11) NOT NULL auto_increment, 
\`domain_id\` int(11) NOT NULL, 
\`password\` varchar(32) NOT NULL, 
\`email\` varchar(100) NOT NULL, 
PRIMARY KEY (\`id\`), 
UNIQUE KEY \`email\` (\`email\`), 
FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE \`virtual_aliases\` (
\`id\` int(11) NOT NULL auto_increment,
\`domain_id\` int(11) NOT NULL,
\`source\` varchar(100) NOT NULL,
\`destination\` varchar(100) NOT NULL,
PRIMARY KEY (\`id\`),
FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# create test data
INSERT INTO \`$MAILDB\`.\`virtual_domains\` (\`id\`, \`name\`) VALUES ('1', '$DOMAIN');
INSERT INTO \`$MAILDB\`.\`virtual_users\` ( \`id\` , \`domain_id\` , \`password\` , \`email\` ) VALUES ( '1', '1', MD5('$EMAILPASS'), '$EMAIL' );
INSERT INTO \`$MAILDB\`.\`virtual_aliases\` ( \`id\`, \`domain_id\`, \`source\`, \`destination\` ) VALUES ( '1', '1', '$EMAIL', '$EMAIL' );
EOF3

mysql -u root -p$MAILDBPASS < ~/mailserver.sql

cat > /etc/postfix/mysql-virtual-mailbox-domains.cf << EOF4
user = $MAILDBUSER
password = $MAILDBPASS
hosts = 127.0.0.1
dbname = $MAILDB
query = SELECT 1 FROM virtual_domains WHERE name='%s'
EOF4

cat > /etc/postfix/mysql-virtual-mailbox-maps.cf << EOF5
user = $MAILDBUSER
password = $MAILDBPASS
hosts = 127.0.0.1
dbname = $MAILDB
query = SELECT 1 FROM virtual_users WHERE email='%s'
EOF5

cat > /etc/postfix/mysql-virtual-alias-maps.cf << EOF6
user = $MAILDBUSER
password = $MAILDBPASS
hosts = 127.0.0.1
dbname = $MAILDB
query = SELECT destination FROM virtual_aliases WHERE source ='%s'
EOF6

cat > /etc/postfix/mysql-email2email.cf << EOF7
user = $MAILDBUSER
password = $MAILDBPASS
hosts = 127.0.0.1
dbname = $MAILDB
query = SELECT email FROM virtual_users WHERE email='%s'
EOF7

postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf
postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf,mysql:/etc/postfix/mysql-email2email.cf

postmap -q "$EMAIL" mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postmap -q "$EMAIL" mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postmap -q "$EMAIL" mysql:/etc/postfix/mysql-virtual-alias-maps.cf
postmap -q "$EMAIL" mysql:/etc/postfix/mysql-email2email.cf

chgrp postfix /etc/postfix/mysql-*.cf
chmod u=rw,g=r,o= /etc/postfix/mysql-*.cf

# setup dovecot
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/vmail -m
chown -R vmail:vmail /var/vmail
chmod u+w /var/vmail

# backup configs
cp /etc/dovecot/conf.d/auth-sql.conf.ext{,.orig}
cp /etc/dovecot/conf.d/10-mail.conf{,.orig}
cp /etc/dovecot/conf.d/10-master.conf{,.orig}
cp /etc/dovecot/conf.d/10-ssl.conf{,.orig}
cp /etc/dovecot/conf.d/15-lda.conf{,.orig}
cp /etc/dovecot/dovecot-sql.conf.ext{,.orig}

sed -i s'/auth_mechanisms = plain/auth_mechanisms = plain login/'g /etc/dovecot/conf.d/10-auth.conf

# disable auth-system.conf.ext and enable auth-sql.conf.ext
sed -i s'/!include auth-system.conf.ext/#!include auth-system.conf.ext/'g /etc/dovecot/conf.d/10-auth.conf
sed -i s'/#!include auth-sql.conf.ext/!include auth-sql.conf.ext/'g /etc/dovecot/conf.d/10-auth.conf

cat > /etc/dovecot/conf.d/auth-sql.conf.ext << EOF8

passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}

userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/vmail/%d/%n
}
EOF8

# mail_location
sed -i 's/mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/mail_location = maildir:\/var\/vmail\/%d\/%n\/Maildir/g' /etc/dovecot/conf.d/10-mail.conf

# namespace inbox separator
sed -i '0,/#separator =/{s/#separator =/separator = ./}' /etc/dovecot/conf.d/10-mail.conf

# update 10-master.conf service auth 
cat > /etc/dovecot/conf.d/10-master.conf << EOF9
service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }
}

service pop3-login {
  inet_listener pop3 {
    #port = 110
  }
  inet_listener pop3s {
    #port = 995
    #ssl = yes
  }
}

service lmtp {
  unix_listener lmtp {
    #mode = 0666
  }
}

service imap {
  # Max. number of IMAP processes (connections)
  #process_limit = 1024
}

service pop3 {
  # Max. number of POP3 processes (connections)
  #process_limit = 1024
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}

service auth-worker {
}

service dict {
  unix_listener dict {
  }
}
EOF9

# ssl dovecot configuration
cat > /etc/dovecot/conf.d/10-ssl.conf << EOF10
ssl_ca = </etc/ssl/certs/cacert.pem
ssl_cert = </etc/ssl/certs/$FQDN.crt
ssl_key = </etc/ssl/private/$FQDN.key
EOF10

# 15-lda.conf
cat > /etc/dovecot/conf.d/15-lda.conf << EOF11
protocol lda {
  mail_plugins = \$mail_plugins sieve
}
EOF11

# dovecot sql configuration
cat > /etc/dovecot/dovecot-sql.conf.ext << EOF12
driver = mysql
connect = host=127.0.0.1 dbname=$MAILDB user=$MAILDBUSER password=$MAILDBPASS
default_pass_scheme = PLAIN-MD5
password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';
EOF12

chgrp vmail /etc/dovecot/dovecot.conf
chmod g+r /etc/dovecot/dovecot.conf
chown root:root /etc/dovecot/dovecot-sql.conf.ext
chmod go= /etc/dovecot/dovecot-sql.conf.ext

service dovecot restart

# Connecting Postfix to Dovecot
echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
echo "  flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f \${sender} -d \${recipient}" >> /etc/postfix/master.cf

service postfix restart

postconf -e virtual_transport=dovecot
postconf -e dovecot_destination_recipient_limit=1
postconf -e 'mynetworks = 127.0.0.0/8'
postconf -e 'mydestination = localhost'
postconf -e smtpd_sasl_type=dovecot
postconf -e smtpd_sasl_path=private/auth
postconf -e smtpd_sasl_auth_enable=yes
postconf -e smtpd_tls_security_level=may
postconf -e smtpd_tls_auth_only=yes
postconf -e smtpd_tls_cert_file=/etc/ssl/certs/$FQDN.crt
postconf -e smtpd_tls_key_file=/etc/ssl/private/$FQDN.key
postconf -e smtpd_recipient_restrictions="\
permit_mynetworks \
permit_sasl_authenticated \
reject_unauth_destination"

apt-get install curl
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
rvm reload
rvm install 1.9.3
rvm use 1.9.3 --default
rvm rubygems latest
gem install sinatra thin mysql
gem install mysql2 --platform=ruby

cd /tmp
wget https://github.com/downloads/germania/mailadmin/mailadmin-0.1.1.tar.gz
tar -xvf mailadmin-0.1.1.tar.gz
mv mailadmin-0.1.1 /var/www/mailadmin
mysql -u root -p$MAILDBPASS mailserver < /var/www/mailadmin/sql/update_db.sql

# make first user admin
mysql -u root -p$MAILDBPASS mailserver -e "update virtual_users set super_admin = 1 where id = 1;"
sed -i 's/DB_PASS = ""/DB_PASS = "'"$MAILDBPASS"'"/g' /var/www/mailadmin/lib/config.rb

# running ruby service in background
apt-get install screen -y
screen -d -m ruby /var/www/mailadmin/run.rb

# enable on reboot:
mkdir /opt/scripts -p

cat > /opt/scripts/autostart.sh << EOF
#!/bin/bash
source /usr/local/rvm/scripts/rvm
screen -d -m ruby /var/www/mailadmin/run.rb
EOF

chmod +x /opt/scripts/autostart.sh
echo '@reboot root /opt/scripts/autostart.sh' > /etc/cron.d/mailadmin

# mailscanning
apt-get install amavisd-new clamav-daemon clamav-testfiles clamav-freshclam spamassassin -y
postconf -e soft_bounce=yes
postfix reload
#postmap /etc/postfix/mynetworks

echo "
amavis    unix  -       -       n       -       5       smtp
  -o smtp_data_done_timeout=1200
  -o smtp_send_xforward_command=yes
  -o smtp_tls_note_starttls_offer=no
127.0.0.1:10025 inet n   -       n       -       -       smtpd
  -o content_filter=
  -o smtpd_delay_reject=no
  -o smtpd_client_restrictions=permit_mynetworks,reject
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o smtpd_data_restrictions=reject_unauth_pipelining
  -o smtpd_end_of_data_restrictions=
  -o smtpd_restriction_classes=
  -o mynetworks=127.0.0.0/8
  -o smtpd_error_sleep_time=0
  -o smtpd_soft_error_limit=1001
  -o smtpd_hard_error_limit=1000
  -o smtpd_client_connection_count_limit=0
  -o smtpd_client_connection_rate_limit=0
  -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks,no_milters
  -o local_header_rewrite_clients=
  -o smtpd_milters=
  -o local_recipient_maps=
  -o relay_recipient_maps= " >> /etc/postfix/master.cf

postfix reload
postconf -e soft_bounce=no
postconf -e content_filter=amavis:[127.0.0.1]:10024
postconf -e receive_override_options=no_address_mappings
service postfix restart

# enabling spam and virus checks
sed -i 's/#@bypass/@bypass/g' /etc/amavis/conf.d/15-content_filter_mode
sed -i 's/#   /   /g' /etc/amavis/conf.d/15-content_filter_mode

adduser clamav amavis
/etc/init.d/clamav-daemon restart
/etc/init.d/amavis restart

# testing:
clamdscan /usr/share/clamav-testfiles/

swaks -t "$EMAIL"@"$DOMAIN" -attach - -server localhost -suppress-data < /usr/share/clamav-testfiles/clam.exe
tail -n 10 /var/log/mail.log

# dkim
apt-get install opendkim opendkim-tools -y
echo SOCKET=\"inet:54321@localhost\" >> /etc/default/opendkim
service opendkim restart
postconf -e smtpd_milters=inet:127.0.0.1:54321
postconf -e non_smtpd_milters=inet:127.0.0.1:54321

# accept mail if theres a dkim issue
postconf -e milter_default_action=accept

cp /etc/opendkim.conf{,.orig}

echo "
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim
OversignHeaders         From" > /etc/opendkim.conf

mkdir /etc/opendkim
mkdir /etc/opendkim/keys

echo "
127.0.0.1
localhost
192.168.1.0/24

\*.$DOMAIN
" > /etc/opendkim/TrustedHosts

echo "mail._domainkey.$DOMAIN $DOMAIN:mail:/etc/opendkim/keys/$DOMAIN/mail.private" > /etc/opendkim/KeyTable
echo "\*@$DOMAIN mail._domainkey.$DOMAIN" > /etc/opendkim/SigningTable
cd /etc/opendkim/keys
mkdir "$DOMAIN"
cd "$DOMAIN"
opendkim-genkey -s mail -d "$DOMAIN"
chown opendkim:opendkim mail.private

# greylisting
apt-get install tumgreyspf -y
echo "tumgreyspf  unix   -       n       n       -       -       spawn
  user=tumgreyspf argv=/usr/bin/tumgreyspf" >> /etc/postfix/master.cf

postconf -e 'smtpd_recipient_restrictions = permit_mynetworks permit_sasl_authenticated reject_rbl_client bl.spamcop.net check_policy_service unix:private/tumgreyspf reject_unauth_destination'

newaliases

a2enmod proxy
service apache2 restart

echo 'Enabling Postgrey Learning Mode:'
sed -i 's/defaultSeedOnly = 0/defaultSeedOnly = 1/g' /etc/tumgreyspf/tumgreyspf.conf

echo 'Restarting Services:'
/etc/init.d/amavis restart
/etc/init.d/clamav-daemon restart
/etc/init.d/clamav-freshclam restart 
/etc/init.d/dovecot restart
/etc/init.d/postfix restart
/etc/init.d/opendkim restart
/etc/init.d/spamassassin restart
/etc/init.d/apache2 restart 

echo "Dumping Info to ~/.creds.txt"

echo "
Postfix, Dovecot, Spamassassin, Amavis, Postgrey, OpenDKIM
Host: $HOST
Fqdn: $FQDN
Domain: $DOMAIN
Email: $EMAIL
Email Password: $EMAILPASS
MySQL DB: $MAILDB
MySQL DB User: $MAILDBUSER
MySQL DB PASS: $MAILDBPASS
Webmail: http://"$FQDN"/roundcube
Mail Admin: http://"$FQDN"/mailadmin
Mail Admin Auth: user - $EMAIL pass - $EMAILPASS
OpenDKIM: /etc/opendkim/keys/mail.txt
" > ~/.creds.txt

echo "DKIM: Update DNS with:"
cat mail.txt