#!/usr/bin/bash
GO_VERSION="1.16.2"

wget https://golang.org/dl/go$GO_VERSION.linux-amd64.tar.gz
sudo bash -c "tar -xf go$GO_VERSION.linux-amd64.tar.gz -C /usr/local"
mkdir -p $HOME/go/{bin,src}
echo 'export GOPATH=$HOME/go' >> ~/.profile
echo 'export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin' >> ~/.profile
source ~/.profile

rm -f go$GO_VERSION.linux-amd64.tar.gz
echo 'Project Structure: $GOPATH/src/github.com/username/project'
go version
