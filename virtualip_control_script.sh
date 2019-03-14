#!/bin/bash

# creates virtual ip addresses
# used for nagios dependency checks:
# https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/dependencies.html
# usage:
# ./script.sh 1 up

interface_id="$1"
action="$2"

ctl_interface1(){
  if [ ${action} == "down" ]
    then ifconfig eth0:1 down
  elif [ ${action} == "up" ]
    then ifconfig eth0:1 192.168.69.1/24 up
  fi
}

ctl_interface2(){
  if [ ${action} == "down" ]
    then ifconfig eth0:2 down
  elif [ ${action} == "up" ]
    then ifconfig eth0:2 192.168.69.2/24 up
  fi
}

ctl_interface3(){
  if [ ${action} == "down" ]
    then ifconfig eth0:3 down
  elif [ ${action} == "up" ]
    then ifconfig eth0:3 192.168.69.3/24 up
  fi
}


if [ -z ${interface_id}  ] || [ -z ${action} ]
  then
    echo fail
    exit 1
    elif [ ${interface_id} == "1" ]
      then
        ctl_interface1 ${action}
    elif [ ${interface_id} == "2" ]
      then
	ctl_interface2 ${action}
    elif [ ${interface_id} == "3" ]
      then
	ctl_interface3 ${action}
    else
        echo "not supported"
fi
