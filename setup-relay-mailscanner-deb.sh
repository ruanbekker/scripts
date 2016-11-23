#!/bin/bash
# relay server with mail scanning on debian
# amavis, spamassassin, clam, postgrey
# still need: opendkim

apt-get  remove exim*
apt-get  remove sendmail*
apt-get update && apt-get upgrade -y
apt-get install vim curl postfix telnet -y
apt-get install swaks -y
apt-get install postgrey -y
mkdir -p /etc/ssl/certs
mkdir -p /etc/ssl/private

openssl req -new -x509 -days 3650 -nodes -newkey rsa:4096 -out /etc/ssl/certs/mailserver.pem -keyout /etc/ssl/private/mailserver.pem
chmod go= /etc/ssl/private/mailserver.pem
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
postconf -e 'smtpd_tls_key_file = /etc/postfix/ssl/smtpd.key'
postconf -e 'smtpd_tls_cert_file = /etc/postfix/ssl/smtpd.crt'
postconf -e 'smtpd_tls_CAfile = /etc/postfix/ssl/cacert.pem'
postconf -e 'smtpd_tls_loglevel = 1'
postconf -e 'smtpd_tls_received_header = yes'
postconf -e 'smtpd_tls_session_cache_timeout = 3600s'
postconf -e 'tls_random_source = dev:/dev/urandom'
postconf -e 'smtpd_recipient_restrictions = reject_unauth_pipelining, reject_non_fqdn_recipient, reject_unknown_recipient_domain, permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, check_sender_access hash:/etc/postfix/restricted_senders, check_recipient_access hash:/etc/postfix/restricted_recipients, reject_rbl_client zen.spamhaus.org, reject_rbl_client bl.spamcop.net, check_policy_service inet:127.0.0.1:10023, permit'
postconf -e 'smtpd_delay_reject = yes'
postconf -e 'smtpd_helo_required = yes'
postconf -e 'smtp_helo_timeout = 60'
postconf -e 'smtpd_helo_restrictions = permit_mynetworks, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname, permit'
postconf -e 'smtpd_sender_restrictions = permit_mynetworks, reject_non_fqdn_sender, reject_unknown_sender_domain, permit'

cat > /etc/postfix/sender_access << EOF
# Black/Whitelist for senders matching the 'MAIL FROM' field. Examples...
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
echo -e "s3kur3\ns3kur3" | passwd relay

mkdir /etc/postfix/ssl
cd /etc/postfix/ssl/
openssl genrsa -des3 -rand /etc/hosts -out smtpd.key 1024
chmod 600 smtpd.key
openssl req -new -key smtpd.key -out smtpd.csr
openssl x509 -req -days 3650 -in smtpd.csr -signkey smtpd.key -out smtpd.crt
openssl rsa -in smtpd.key -out smtpd.key.unencrypted
mv -f smtpd.key.unencrypted smtpd.key
openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650

sed -i 's/#submission/submission/g' /etc/postfix/master.cf

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

su - amavis -s /bin/bash
razor-admin -create
razor-admin -register
pyzor discover
exit

sed -i 's/AllowSupplementaryGroups false/AllowSupplementaryGroups true/g' /etc/clamav/clamd.conf

/etc/init.d/clamav-daemon restart
/etc/init.d/amavis restart

for x in postfix amavis clamav-daemon saslauthd; do service $x restart; done

clamdscan /usr/share/clamav-testfiles/
swaks -t ruan@ruanbekker.com --attach - -server localhost --suppress-data < /usr/share/clamav-testfiles/clam.exe
tail -n 100 /var/log/mail.log