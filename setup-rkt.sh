#!/bin/bash

cd /opt
wget https://github.com/coreos/rkt/releases/download/v1.0.0/rkt-v1.0.0.tar.gz
tar xfv rkt-v1.0.0.tar.gz
echo "PATH=\$PATH:/opt/rkt-v1.0.0" > /etc/profile.d/rkt.sh
rm -rf rkt-v1.0.0.tar.gz

echo "Getting Started Guide: "
echo "-> https://coreos.com/blog/getting-started-with-rkt-1.0.html "