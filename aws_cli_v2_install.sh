#!/usr/bin/env bash
export PATH=${PATH}:/usr/local/bin

# install dependencies
# unzip wget jq 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws
aws --version
