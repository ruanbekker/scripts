#!/bin/bash

# info:
# basic script to create containers with openvz

#!/bin/bash

echo "Container OS (ubuntu-14.04-x86_64|centos-6-x86_64) : "
read ct_os

echo "Container Memory (512m|1024m|2048m) : "
read ct_mem

echo "Container Name: "
read ct_name

echo "Container IP: "
read ct_ip

# variables
vmname=$ct_name
vmip=$ct_ip
vmtemplate=$ct_os

# detect last used container id
lastctid=`vzlist -a | tail -n 1 | awk '{print $1}'`
ctid=`for x in $lastctid; do echo $x + 1 | bc > /tmp/ctid ; done`
newctid=`cat /tmp/ctid`

# generating new ctid
echo "New CTID is:$ctid $newctid"

# functions
create_vm() {

vzctl create $newctid --ostemplate $vmtemplate --config vswap-512m
vzctl set $newctid --save --name $vmname
vzctl set $newctid --save --onboot yes
vzctl set $newctid --save --hostname $vmname.ovz.lan.bekkers.co.za
vzctl set $newctid --save --ipadd $vmip
vzctl set $newctid --save --searchdomain lan.bekkers.co.za
vzctl set $newctid --save --nameserver 172.16.1.1 --nameserver 8.8.8.8
vzctl set $newctid --save --cpus 1
vzctl set $newctid --save --ram $ct_mem
#vzctl set $newctid --save --netif_add eth0 --ipadd 10.0.0.3
vzctl set $newctid --save --diskspace 20G
vzctl set $newctid --save --netfilter full
vzctl set $newctid --save --capability sys_admin:on

}

echo "Creating VM"
create_vm
sleep 5
echo "Container launched with CTID: $(vzlist -a | tail -n 1 | awk '{print $1}')"
sleep 5
echo " "
echo "Starting Container: $(vzlist -a | tail -n 1 | awk '{print $1}')"
vzctl start $newctid
echo "Container $vmname with CTID: $(vzlist -a | tail -n 1 | awk '{print $1}') was started and available at: $vmip "

