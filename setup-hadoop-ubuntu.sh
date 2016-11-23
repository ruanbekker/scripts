#!/bin/bash
# in progress
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install openjdk-7-jdk -y
cd /usr/lib/jvm
sudo ln -s java-7-openjdk-amd64/ jdk
mkdir -p /home/hadoop/mydata/hdfs/namenode
mkdir -p /home/hadoop/mydata/hdfs/datanode

# users
addgroup hadoop
useradd -g hadoop hadoop
usermod -a -G hadoop,sudo hadoop
echo "%hadoop ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers