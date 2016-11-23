#!/bin/bash

cd /opt/
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"

tar xzf jdk-7u79-linux-x64.tar.gz
cd /opt/jdk1.7.0_79/
alternatives --install /usr/bin/java java /opt/jdk1.7.0_79/bin/java 2
alternatives --set java /opt/jdk1.7.0_79/bin/java
alternatives --install /usr/bin/jar jar /opt/jdk1.7.0_79/bin/jar 2
alternatives --install /usr/bin/javac javac /opt/jdk1.7.0_79/bin/javac 2
alternatives --set jar /opt/jdk1.7.0_79/bin/jar
alternatives --set javac /opt/jdk1.7.0_79/bin/javac 

cat > /etc/profile.d/java.sh << EOF
JAVA_HOME=/opt/jdk1.7.0_79
JRE_HOME=/opt/jdk1.7.0_79/jre
PATH=$PATH:/opt/jdk1.7.0_79/bin:/opt/jdk1.7.0_79/jre/bin
EOF

source /etc/profile.d/java.sh
rm -rf jdk-7u79-linux-x64.tar.gz
