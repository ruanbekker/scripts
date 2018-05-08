#!/usr/bin/env bash

apt update && apt upgrade -y && apt install curl git apt-transport-https ca-certificates software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update && apt install docker-ce -y
systemctl enable docker
systemctl restart docker
docker run hello-world
