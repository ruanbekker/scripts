#!/bin/bash

cat > /etc/apt/sources.list.d/java-8.list << EOF
deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main
deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main
EOF

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
apt-get update
apt-get install oracle-java8-installer -y
apt-get install oracle-java8-set-default -y