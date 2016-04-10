#!/bin/bash

# info:
# basic script to create containers with openvz

# variables
vmname="puppet-client"
vmip="192.168.1.79"
vmtemplate="centos-6-x86_64"

lastctid=`vzlist -a | tail -n 1 | awk '{print $1}'`
ctid=`for x in $lastctid; do echo $x + 1 | bc > /tmp/ctid ; done`
newctid=`cat /tmp/ctid`

# generating ctid
echo "New CTID is:$ctid $newctid"

# functions
create_vm() {

vzctl create $newctid --ostemplate $vmtemplate --config vswap-512m
vzctl set $newctid --save --name $vmname
vzctl set $newctid --save --onboot yes
vzctl set $newctid --save --hostname $vmname.ovz.lan.bekkers.co.za
vzctl set $newctid --save --ipadd $vmip
vzctl set $newctid --save --searchdomain lan.bekkers.co.za
vzctl set $newctid --save --nameserver 192.168.1.154 --nameserver 8.8.8.8
vzctl set $newctid --save --cpus 1
vzctl set $newctid --save --ram 512m
vzctl set $newctid --save --diskspace 8G
vzctl set $newctid --save --netfilter full
vzctl set $newctid --save --capability sys_admin:on

}

echo "Creating VM"
create_vm
echo "Container launched with CTID: $(vzlist -a | tail -n 1 | awk '{print $1}')"
echo " "
echo "Starting Container: $(vzlist -a | tail -n 1 | awk '{print $1}')"
vzctl start $newctid
echo " "
echo "Container with CTID: $(vzlist -a | tail -n 1 | awk '{print $1}') was started"
