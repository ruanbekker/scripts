#!/bin/bash

cd ~
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.rpm"
yum localinstall jdk-8u65-linux-x64.rpm
rm -rf jdk-8u65-linux-x64.rpm

rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch

wget -O /etc/yum.repos.d/elasticsearch-2.repo https://gitlab.com/rbekker87/configs/raw/master/repos/rhel/elasticsearch-2.repo

yum -y install elasticsearch
sed -i s'/# network.host: 192.168.0.1/network.host: 127.0.0.1/'g /etc/elasticsearch/elasticsearch.yml
service elasticsearch start
chkconfig elasticsearch on
