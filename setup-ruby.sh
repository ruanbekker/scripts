#!/bin/bash
yum update -y
yum install gcc-c++ patch readline readline-devel zlib zlib-devel -y
yum install libyaml-devel libffi-devel openssl-devel make -y
yum install bzip2 autoconf automake libtool bison iconv-devel sqlite-devel -y
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
#rvm list known
#rvm list rubies


if [[ `type rvm | head -1` = "rvm is a function" ]] ;
  then
    echo "RVM has been installed";
  else
    echo "Error: RVM has not been installed";
    exit 0;
fi

rvm reload
rvm install 2.2
rvm use 2.2 --default
gem update
gem update --system --no-document