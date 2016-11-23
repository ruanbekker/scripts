#!/bin/bash
yum install net-snmp-utils php-snmp net-snmp-libs -y
mv /etc/snmp/snmpd.conf{,.bak}
wget -O /etc/snmp/snmpd.conf https://gitlab.com/rbekker87/configs/raw/master/snmp/snmpd.conf.txt
sed -i "s/myhostname/$(hostname -f)/g" /etc/snmp/snmpd.conf
service snmpd restart
chkconfig snmpd on