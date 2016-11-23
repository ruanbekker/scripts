#!/bin/bash

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install lxc lxctl lxc-templates -y
sudo lxc-create --name test --template ubuntu
