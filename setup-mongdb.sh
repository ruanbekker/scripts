#!/bin/bash

create_repo() {

echo "
[MongoDB]
name=MongoDB Repository
baseurl=http://repo.mongodb.org/yum/redhat/6/mongodb-org/3.2/x86_64/
gpgcheck=0
enabled=1
" > /etc/yum.repos.d/mongodb.repo

}

install_packages() {

 yum update -y
 yum install mongodb-org* -y
 mkdir -p /data/db
}

start_service() {
    
    /etc/init.d/mongod restart
}

if [ -f /etc/yum.repos.d/mongodb.repo ];
  then
    install_packages
  else
    create_repo
    install_packages
    start_service
fi
