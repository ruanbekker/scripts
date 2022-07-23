#!/bin/bash
# deploys a privileged lxc container on lxd
ctn="$1"

echo "initializing ${ctn}"
lxc init images:ubuntu/bionic/amd64 --profile privileged $ctn
lxc config device add "${ctn}" "kmsg" unix-char source="/dev/kmsg" path="/dev/kmsg"
lxc start $ctn
sleep 5

echo "creating update script"
cat > ${ctn}_updates.sh << EOF
apt update && apt upgrade -y
EOF

echo "moving ${ctn}_updates.sh to ${ctn}/updates.sh"
lxc file push ${ctn}_updates.sh ${ctn}/updates.sh

echo "running updates"
lxc exec ${ctn} -- bash /updates.sh

echo "removing script"
rm -rf ${ct}_updates.sh

lxc list ${ctn}
