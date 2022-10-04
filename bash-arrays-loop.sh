#!/usr/bin/env bash

local_users=("ruan" "stefan")
git_users=("ruan.bekker" "stefan.bester")

for u in ${!local_users[@]}
  do
    localuser=${local_users[$u]}
    gituser=${git_users[$u]}
    echo "useradd -m -s /bin/bash $localuser"
    echo "mkdir -p /home/$localuser/.ssh"
    echo "fetch keys from /store/keys/$gituser"
    echo "chown -R $localuser:$localuser /home/$localuser/"
    echo ""
  done
