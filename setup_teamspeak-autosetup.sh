#!/bin/bash

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Teamspeak
iptables -I INPUT -p udp --dport 9987 -j ACCEPT
iptables -I INPUT -p udp --sport 9987 -j ACCEPT
iptables -I INPUT -p tcp --dport 30033 -j ACCEPT
iptables -I INPUT -p tcp --sport 30033 -j ACCEPT
iptables -I INPUT -p tcp --dport 10011 -j ACCEPT
iptables -I INPUT -p tcp --sport 10011 -j ACCEPT

# HTTP(s)
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --sport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --sport 443 -j ACCEPT

# SSH
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp --sport 22 -j ACCEPT

# DNS
iptables -I INPUT -p udp --dport 53 -j ACCEPT
iptables -I INPUT -p udp --sport 53 -j ACCEPT

service iptables save && service iptables restart

# Update system
yum -y update

# Add Teamspeak user
useradd teamspeak

# Download, unzip and cleanup Teamspeak
cd /home/teamspeak
wget http://ftp.4players.de/pub/hosted/ts3/releases/3.0.7.1/teamspeak3-server_linux-amd64-3.0.7.1.tar.gz
tar xvfz teamspeak3-server_linux-amd64-3.0.7.1.tar.gz
mv teamspeak3-server_linux-amd64/* `pwd`
rm -rf teamspeak3-server_linux-amd64 && rm -rf teamspeak3-server_linux-amd64-3.0.7.1.tar.gz

# Add chkconfig support to startup file and link to binary
sed -i 's/# All rights reserved/# All rights reserved\n# chkconfig: 2345 99 00/g' ts3server_startscript.sh
ln -s /home/teamspeak/ts3server_startscript.sh /etc/init.d/teamspeak

# Change permissions of Teamspeak
chown -R teamspeak:teamspeak /home/teamspeak
chown -R teamspeak:teamspeak /etc/init.d/teamspeak

# Remount shared memory - http://support.teamspeakusa.com/index.php?/Knowledgebase/Article/View/51
mount -t tmpfs tmpfs /dev/shm

# Change to Teamspeak user and run server
su teamspeak
service teamspeak start

echo "Teamspeak IP is: `curl ip.ruanbekker.com`"

