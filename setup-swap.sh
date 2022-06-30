#!/usr/bin/env bash

loadswap() {
 sudo dd if=/dev/zero of=/opt/swapfile.swp bs=1M count=2048
 sudo chmod 0600 /opt/swapfile.swp
 sudo mkswap /opt/swapfile.swp
 sudo swapon /opt/swapfile.swp
}

unloadswap() {
 sudo swapoff /opt/swapfile.swp
}

if [[ $1 = "start" ]];
  then loadswap;
elif [[ $1 = "stop" ]];
  then unloadswap;
    else echo "Usage: $0 (start|stop)" ;
fi

