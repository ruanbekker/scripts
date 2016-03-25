#!/bin/bash

# Ruan Bekker <ruan@ruanbekker.com>
# Sources:
# http://xmodulo.com/mailscanner-clam-antivirus-spamassassin-centos.html
# mailscanner setup 01

yum update -y
rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

yum install epel-release -y
yum-config-manager --disable rpmforge

yum --enablerepo=rpmforge install unrar -y

yum install -y yum-utils gcc cpp perl bzip2 zip unrar make patch automake rpm-build perl-Archive-Zip perl-Filesys-Df perl-OLE-Storage_Lite perl-Sys-Hostname-Long perl-Sys-SigAction perl-Net-CIDR perl-DBI perl-MIME-tools perl-DBD-SQLite binutils glibc-devel perl-Filesys-Df zlib zlib-devel wget mlocate

yum install clamav spamassassin -y
freshclam -v
sa-update
service spamassassin start
chkconfig spamassassin on
ln -s /usr/bin/freshclam /usr/local/bin/freshclam
service postfix stop
chkconfig postfix off

grep -o '^[^#]*' /etc/postfix/main.cf > /etc/postfix/main.cf2
mv /etc/postfix/main.cf /etc/postfix/main-cf-orig
mv /etc/postfix/main.cf2 /etc/postfix/main.cf

postconf -e "header_checks = regexp:/etc/postfix/header_checks"
postconf -e "inet_interfaces = all"
echo "/^Received:/ HOLD" > /etc/postfix/header_checks

#wget https://s3.amazonaws.com/mailscanner/release/v4/rpm/MailScanner-4.85.2-3.rpm.tar.gz
wget http://repo.ruanbekker.com/packages/MailScanner-4.85.2-3.rpm.tar.gz

tar -xvf MailScanner-4.85.2-3.rpm.tar.gz
cd MailScanner-4.85.2-3
./install.sh

chkconfig MailScanner on

mkdir /var/spool/MailScanner/spamassassin -p
chown -R postfix /var/spool/MailScanner/spamassassin
chown -R postfix /var/spool/MailScanner/incoming

mv /etc/MailScanner/MailScanner.conf  /etc/MailScanner/MailScanner-bak-conf
wget -O /etc/MailScanner/MailScanner.conf repo.ruanbekker.com/configs/MailScanner.conf

MailScanner -lint
service MailScanner start

# test spam: XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
