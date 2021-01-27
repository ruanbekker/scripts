#!/usr/bin/env bash

create_swap(){
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
}

remove_swap(){
  if [ -f /swapfile ]
    then
      swapoff -v /swapfile
      rm -rf /swapfile
    else
      echo "swap is not active"
  fi
}

load_5m=$(uptime | awk -F 'load average:' '{print $2}' | cut -d ',' -f2 | awk '{print $1}' | cut -d '.' -f1)

if [ "${load_5m}" -gt "4" ]
  then
    echo "Load is currently: ${load_5m}, setting up swap"
    create_swap
  else
    echo "Load is currently: ${load_5m}, removing swap"
    remove_swap
fi
