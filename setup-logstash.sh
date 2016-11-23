#!/bin/bash

YUM=`which yum 2>/dev/null | wc -l`
APT=`which apt 2>/dev/null | wc -l`
JAVA=`which java 2>/dev/null | wc -l`

setupJava7() {
    curl https://gitlab.com/rbekker87/scripts/raw/master/setup-java7-centos.sh | sh
}

setupLogstashYUM () {
    rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
    wget -O /etc/yum.repos.d/logstash-2.4.repo https://gitlab.com/rbekker87/configs/raw/master/repos/rhel/logstash-2.4.repo
    yum install logstash -y
}

setupLogstashAPT() {
    wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://packages.elastic.co/logstash/2.4/debian stable main" | sudo tee -a /etc/apt/sources.list
    sudo apt-get update
    sudo apt-get install logstash -y
}

if [ $YUM = "1" ] && [ $JAVA = "1" ] ;
    then 
        echo 'OK: Java is Installed, proceeding to install Logstash with YUM'
        sleep 5
        setupLogstashYUM

    elif [ $YUM = "1" ] && [ $JAVA = "0" ] ;
        then
            echo 'Java is not Installed, proceeding to install'
            setupJava7
            sleep 5
            setupLogstashYUM
    
    elif [ $APT = "1" ] && [ $JAVA = "0" ] ;
        then
            echo 'ERROR: Java needs to be installed first'
            exit 0
            
    elif [ $APT = "1" ] && [ $JAVA = "1" ] ;
        then
            echo 'OK: Java is Installed, proceeding to install Logstash with APT'
            setupLogstashAPT
            
    else
        echo 'ERROR: Exception Occured'
        exit 0

fi