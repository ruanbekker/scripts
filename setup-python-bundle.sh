#!/bin/bash


function setup_dependencies_rhel(){
  yum update -y
  yum groupinstall 'development tools' -y
  yum install git python python-devel lib-devel libevent-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel zlib zlib-devel xz-devel gcc gcc-c++ kernel-devel -y
  echo "include ld.so.conf.d/*.conf" > /etc/ld.so.conf
  echo "/usr/local/lib" >> /etc/ld.so.conf
}

function setup_dependencies_deb(){
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install libssl-dev zlib1g-dev -y
}


function setup_python27(){
  # python 2.7.6
  wget http://python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz
  tar xf Python-2.7.6.tar.xz
  cd Python-2.7.6
  ./configure --prefix=/usr/local --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
  make && make altinstall
  curl https://bootstrap.pypa.io/ez_setup.py | python2.7
  easy_install-2.7 pip
  pip2.7 install virtualenv
  virtualenv -p /usr/local/bin/python2.7 my27project
  #virtualenv-2.7 my27project
}

function setup_python33(){
  # Python 3.3.5:
  wget http://python.org/ftp/python/3.3.5/Python-3.3.5.tar.xz
  tar xf Python-3.3.5.tar.xz
  cd Python-3.3.5
  ./configure --prefix=/usr/local --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
  make && make altinstall
  curl https://bootstrap.pypa.io/ez_setup.py | python3.3
  easy_install-3.3 pip
  pip3.3 install virtualenv
  virtualenv -p /usr/local/bin/python3.3 my33project
  #virtualenv-3.3 my37project
}

function setup_python34(){
  #curl https://bootstrap.pypa.io/get-pip.py | python
  #easy_install pip
  #pip install pip --upgrade
  #pip install virtualenv

  cd /usr/src
  wget https://www.python.org/ftp/python/3.4.4/Python-3.4.4.tgz
  tar xzf Python-3.4.4.tgz
  cd Python-3.4.4
  ./configure --with-zlib-dir=/usr/local/lib --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
  make && make altinstall
  curl https://bootstrap.pypa.io/ez_setup.py | python3.4
  easy_install-3.4 pip
  pip3.4 install virtualenv
  virtualenv -p /usr/local/bin/python3.4 my34project
  #virtualenv-3.4 my34project
}

if [ -z "$1" ] ;
  then echo "Usage: $0 (python27|python33|python34)"
  elif
    [ "$1" = "python27" ] ;
    then 
      setup_dependencies_rhel # still need to get ubuntu/rhel if
      setup_python27
  elif
    [ "$1" = "python33" ] ;
    then 
      setup_dependencies
      setup_python33
  elif
    [ "$1" = "python34" ] ;
    then 
      setup_dependencies
      setup_python34
fi