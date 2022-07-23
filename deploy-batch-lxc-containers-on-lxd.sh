#!/usr/bin/env bash
for vm in 01 02 03 etcd haproxy
do
	lxc init images:debian/10/cloud postgres-${vm}
	lxc config set postgres-${vm} limits.memory 1024MB
	lxc config set postgres-${vm} security.privileged true
	lxc config set ${vm} security.nesting true
	cat <<EOT | lxc config set ${vm} raw.lxc -
lxc.cgroup.devices.allow = a
lxc.cap.drop =
EOT
	lxc start postgres-${vm}
done
