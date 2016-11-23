#!/bin/bash
yum update -y
yum groupinstall "Development Tools" -y 
curl --silent --location https://rpm.nodesource.com/setup_4.x | bash -
yum install nodejs -y
npm -g install npm@latest
