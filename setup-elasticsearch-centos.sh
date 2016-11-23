#!/bin/bash

setupJava() {
  curl https://gitlab.com/rbekker87/scripts/raw/master/setup-java8-centos.sh | sh
}

setupElasticSearch() {

rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

cat > /etc/yum.repos.d/es.repo << EOF
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=https://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF

yum update
yum install elasticsearch -y
chkconfig --add elasticsearch
/etc/init.d/elasticsearch restart

}

yum install which -y

if [ `which /usr/bin/java` = "1" ] ;

    then "setupElasticSearch"
    else 
        "setupJava"
        "setupElasticSearch"
        
fi