#!/bin/bash

loadswap() {
 dd if=/dev/zero of=/opt/swapfile.swp bs=1M count=2048
 chmod 0600 /opt/swapfile.swp
 mkswap /opt/swapfile.swp
 swapon /opt/swapfile.swp
}

unloadswap() {
 swapoff /opt/swapfile.swp
}

if [[ $1 = "start" ]];
  then loadswap;
elif [[ $1 = "stop" ]];
  then unloadswap;
    else echo "Usage: $0 (start|stop)" ;
fi

