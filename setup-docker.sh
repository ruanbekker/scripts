#!/usr/bin/env bash
DC_VERSION="2.10.0"

curl https://get.docker.com | bash
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/download/v$DC_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
