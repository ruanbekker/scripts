#!/bin/bash

# ================================ # 
#  Relay Server with:              # 
#  - Spamassassin, Amavis, ClamAv  # 
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
# debconf-get-selections | grep mysql

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

apt-get remove exim* -y
apt-get remove sendmail* -y
apt-get update && apt-get upgrade -y
apt-get install --reinstall systemd dbus -y

debconf-set-selections <<< "postfix postfix/mailname string $FQDN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get install apt-utils -y
apt-get install ca-certificates -y
update-ca-certificates
apt-get install build-essential debconf-utils mailutils -y
apt-get install libsqlite3-dev zlib1g-dev libncurses5-dev libgdbm-dev libbz2-dev  libssl-dev libdb-dev -y
apt-get install sudo syslog-ng ssh openssh-server wget curl tcpdump netcat vim gnupg2 vim curl postfix telnet -y

apt-get install swaks -y
apt-get install postgrey -y

# VARIABLES:
export DOMAIN="$set_domain"
export EMAILPASS=$(openssl rand -hex 4)
export HOST="$set_host"
export FQDN="$set_fqdn"

echo "
Host: $HOST
Fqdn: $FQDN
Domain: $DOMAIN
Email: $EMAIL
Email Password: $EMAILPASS
" > ~/.creds.txt


mkdir -p /etc/ssl/certs
mkdir -p /etc/ssl/private


openssl genrsa -des3 -passout pass:$EMAILPASS -out /etc/ssl/private/$FQDN.key 2048
chmod 0600 /etc/ssl/private/$FQDN.key
openssl req -new -key /etc/ssl/private/$FQDN.key -out /root/$FQDN.csr -passin pass:$EMAILPASS -subj "/C=ZA/ST=CapeTown/O=Tech/OU=Hosting/CN=$DOMAIN"
openssl x509 -req -days 365 -in /root/$FQDN.csr -signkey /etc/ssl/private/$FQDN.key -out /etc/ssl/certs/$FQDN.crt -passin pass:$EMAILPASS
openssl rsa -in /etc/ssl/private/$FQDN.key -out /etc/ssl/private/$FQDN.nopass.key -passin pass:$EMAILPASS
chmod 0600 /etc/ssl/private/$FQDN.nopass.key
openssl req -new -x509 -extensions v3_ca -keyout /etc/ssl/private/cakey.pem -out /etc/ssl/certs/cacert.pem -days 3650 -passout pass:$EMAILPASS -subj "/C=ZA/ST=CapeTown/O=Tech/OU=Hosting/CN=$DOMAIN"
chmod 0600 /etc/ssl/private/cakey.pem
mv /etc/ssl/private/$FQDN.nopass.key /etc/ssl/private/$FQDN.key

apt-get install libsasl2-2 sasl2-bin libsasl2-modules -y
sed -i s'/START=no/START=yes/g' /etc/default/saslauthd

postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'smtpd_sasl_security_options = noanonymous'
postconf -e 'smtpd_sasl_local_domain ='
postconf -e 'broken_sasl_auth_clients = yes'
#postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination,reject_unauth_pipelining,reject_non_fqdn_recipient,reject_unknown_recipient_domain,check_sender_access hash:/etc/postfix/restricted_senders,check_recipient_access hash:/etc/postfix/restricted_recipients,reject_rbl_client zen.spamhaus.org,reject_rbl_client bl.spamcop.net,check_policy_service unix:postgrey/socket,permit'
postconf -e 'inet_interfaces = all'
postconf -e 'smtpd_tls_auth_only = no'
postconf -e 'smtp_use_tls = yes'
postconf -e 'smtpd_use_tls = yes'
postconf -e 'smtp_tls_note_starttls_offer = yes'
postconf -e "smtpd_tls_key_file = /etc/ssl/private/$FQDN.key"
postconf -e "smtpd_tls_cert_file = /etc/ssl/certs/$FQDN.crt"
postconf -e "smtpd_tls_CAfile = /etc/ssl/certs/cacert.pem"
postconf -e 'smtpd_tls_loglevel = 1'
postconf -e 'smtpd_tls_received_header = yes'
postconf -e 'smtpd_tls_session_cache_timeout = 3600s'
postconf -e 'transport_maps = hash:/etc/postfix/transport'
postconf -e 'tls_random_source = dev:/dev/urandom'
postconf -e 'smtpd_recipient_restrictions = reject_unauth_pipelining, reject_non_fqdn_recipient, reject_unknown_recipient_domain, permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, check_sender_access hash:/etc/postfix/restricted_senders, check_recipient_access hash:/etc/postfix/restricted_recipients, reject_rbl_client zen.spamhaus.org, reject_rbl_client bl.spamcop.net, check_policy_service inet:127.0.0.1:10023, check_policy_service unix:private/policyd-spf, permit'
postconf -e 'smtpd_delay_reject = yes'
postconf -e 'smtpd_helo_required = yes'
postconf -e 'smtp_helo_timeout = 60'
postconf -e 'smtpd_helo_restrictions = permit_mynetworks, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname, permit'
postconf -e 'smtpd_sender_restrictions = permit_mynetworks, reject_non_fqdn_sender, reject_unknown_sender_domain, permit'

cat > /etc/postfix/sender_access << EOF
# Black/Whitelist for senders matching the 'MAIL FROM' field. 
myfriend@hisdomain.com        OK
junk@spam.com                REJECT
marketing@                    REJECT
theboss@                    OK
deals.marketing.com            REJECT
mydomain.com                OK
EOF

cat > /etc/postfix/restricted_recipients << EOF
bad@mail.org    REJECT
EOF

cat > /etc/postfix/restricted_senders << EOF
bad@mail.org    REJECT
EOF

echo 'nonfqdn.com smtp:1.2.3.4' > /etc/postfix/transport

postmap /etc/postfix/transport
postmap /etc/postfix/restricted_recipients
postmap /etc/postfix/sender_access
postmap /etc/postfix/restricted_senders

apt-get install libnet-dns-perl libmail-spf-perl pyzor razor -y
apt-get install arj bzip2 cabextract cpio file gzip  nomarch pax unzip  zip zoo -y
wget http://debian.mirror.ac.za/debian/pool/non-free/u/unrar-nonfree/unrar_4.1.4-1+deb7u1_amd64.deb
dpkg -i unrar_4.1.4-1+deb7u1_amd64.deb
wget http://debian.mirror.ac.za/debian/pool/non-free/r/rar/rar_4.0.b3-1_amd64.deb
dpkg -i rar_4.0.b3-1_amd64.deb

echo 'pwcheck_method: saslauthd' > /etc/postfix/sasl/smtpd.conf
echo 'mech_list: plain login' >> /etc/postfix/sasl/smtpd.conf

useradd -c 'Relay Account' -s /sbin/nologin relay
echo -e "passwd\npasswd" | passwd relay

sed -i 's/#submission/submission/g' /etc/postfix/master.cf
sed -i 's/#smtps/smtps/g' /etc/postfix/master.cf

/etc/init.d/postfix restart

cat > /etc/default/saslauthd << EOF
START=yes
DESC="SASL Authentication Daemon"
NAME="saslauthd"
MECHANISMS="pam"
MECH_OPTIONS=""
THREADS=5
OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"
EOF

mkdir -p /var/spool/postfix/var/run/saslauthd
dpkg-statoverride --add root sasl 710 /var/spool/postfix/var/run/saslauthd
adduser postfix sasl
/etc/init.d/saslauthd restart

apt-get install amavisd-new clamav-daemon clamav-testfiles clamav-freshclam spamassassin -y
sed -i 's/ENABLED=0/ENABLED=1/'g /etc/default/spamassassin
/etc/init.d/spamassassin restart
/etc/init.d/clamav-daemon restart
/etc/init.d/clamav-freshclam stop
freshclam -v
/etc/init.d/clamav-freshclam start

echo "amavis unix - - - - 2 smtp
  -o smtp_data_done_timeout=1200
  -o smtp_send_xforward_command=yes
smtp-amavis unix - - n - 2 smtp
  -o smtp_data_done_timeout=2400
  -o smtp_send_xforward_command=yes
  -o disable_dns_lookups=yes
  -o max_use=20
127.0.0.1:10025 inet n - n - - smtpd
  -o content_filter=
  -o local_recipient_maps=
  -o relay_recipient_maps=
  -o smtpd_restriction_classes=
  -o smtpd_delay_reject=no
  -o smtpd_client_restrictions=permit_mynetworks,reject
  -o smtpd_helo_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks_style=host
  -o mynetworks=127.0.0.0/8
  -o strict_rfc821_envelopes=yes
  -o smtpd_error_sleep_time=0
  -o smtpd_soft_error_limit=1001
  -o smtpd_hard_error_limit=1000
  -o smtpd_client_connection_count_limit=0
  -o smtpd_client_connection_rate_limit=0
  -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks,no_address_mappings" >> /etc/postfix/master.cf

postfix reload
postconf -e 'content_filter=amavis:[127.0.0.1]:10024'
postconf -e 'receive_override_options=no_address_mappings'
service postfix restart

cat > /etc/amavis/conf.d/15-content_filter_mode << EOF
use strict;

# Virus Checks
@bypass_virus_checks_maps = (
   \%bypass_virus_checks, \@bypass_virus_checks_acl, \$bypass_virus_checks_re);


# SPAM Checks
@bypass_spam_checks_maps = (
   \%bypass_spam_checks, \@bypass_spam_checks_acl, \$bypass_spam_checks_re);

1;
EOF

adduser clamav amavis
adduser amavis clamav

sudo -u clamav 'razor-admin -create'
sudo -u clamav 'razor-admin -register'
sudo -u clamav 'pyzor dicover'

sed -i 's/AllowSupplementaryGroups false/AllowSupplementaryGroups true/g' /etc/clamav/clamd.conf

# dkim
apt-get install opendkim opendkim-tools postfix-policyd-spf-python -y
adduser postfix opendkim

sed -i 's/HELO_reject = SPF_Not_Pass/HELO_reject = False/g' /etc/postfix-policyd-spf-python/policyd-spf.conf
sed -i 's/Mail_From_reject = Fail/Mail_From_reject = False/g' /etc/postfix-policyd-spf-python/policyd-spf.conf

echo 'policyd-spf  unix  -       n       n       -       0       spawn' >> /etc/postfix/master.cf
echo '    user=policyd-spf argv=/usr/bin/policyd-spf' >> /etc/postfix/master.cf

postconf -e 'policyd-spf_time_limit = 3600'

echo SOCKET=\"inet:54321@localhost\" >> /etc/default/opendkim
service opendkim restart
postconf -e smtpd_milters=inet:127.0.0.1:54321
postconf -e non_smtpd_milters=inet:127.0.0.1:54321

# accept mail if theres a dkim issue
postconf -e milter_default_action=accept

#mkdir /etc/postfix/dkim
#cd /etc/postfix/dkim

#opendkim-genkey -b 1024 -d example.org -s example.org
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

echo 'Enabling Postgrey Learning Mode:'
sed -i 's/defaultSeedOnly = 0/defaultSeedOnly = 1/g' /etc/tumgreyspf/tumgreyspf.conf

for x in postfix amavis clamav-daemon saslauthd spamassassin opendkim postgrey; do /etc/init.d/$x restart; done

clamdscan /usr/share/clamav-testfiles/
swaks -t ruan@ruanbekker.com --attach - -server localhost --suppress-data < /usr/share/clamav-testfiles/clam.exe
tail -n 100 /var/log/mail.log

echo 'Done'
echo "Update DNS with:"
cat mail.txt
echo 'creds at : ~/.creds.txt'
