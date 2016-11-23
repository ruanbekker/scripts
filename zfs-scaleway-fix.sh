#!/bin/bash
#
# zfs issue with Ubuntu16 on Scaleway
#
apt-get update
apt-get install libssl-dev -y
apt-get install zfsutils-linux -y
zcat /proc/config.gz > /boot/config-4.5.7
cd /tmp;  wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.5.7.tar.xz && tar xf linux-4.5.7.tar.xz
cp -r /tmp/linux-4.5.7 /lib/modules/4.5.7-std-3/build && cd /lib/modules/4.5.7-std-3/build/
cp /boot/config-4.5.7 .config
make oldconfig
make prepare scripts
apt-get remove zfsutils-linux -y
apt-get install zfsutils-linux -y
cd /lib/modules/4.5.7-std-3/build && make -j4
dkms --verbose install spl/0.6.5.6
dkms --verbose install zfs/0.6.5.6
dkms status
modprobe zfs
zpool list