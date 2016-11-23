#!/bin/bash
# Setup Docker for Debian Jessie (8)

apt-get update && apt-get upgrade -y
apt-get install git vim -y
apt-get purge "lxc-docker*" -y
apt-get purge "docker.io*" -y
apt-get install apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo 'deb https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list
apt-get update
apt-cache policy docker-engine
apt-get update
apt-get install docker-engine -y
systemctl enable docker
systemctl start docker.service
systemctl status docker.service