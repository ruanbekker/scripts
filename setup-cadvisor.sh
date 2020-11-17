#!/usr/bin/env bash

CADVISOR_VERSION="0.37.0"

if [ -d /usr/local/bin ] 
  then 
    echo "directory exists, using it"
    export BIN_DIRECTORY="/usr/local/bin"
  else 
    echo "directory does not exist, using one level back"
    export BIN_DIRECTORY="/usr/local"
fi

cd /tmp
wget https://github.com/google/cadvisor/releases/download/v${CADVISOR_VERSION}/cadvisor
chmod +x ./cadvisor
mv ./cadvisor ${BIN_DIRECTORY}/cadvisor

cat > /etc/systemd/system/cadvisor.service << EOF
[Unit]
Description=cAdvisor
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
ExecStart=${BIN_DIRECTORY}/cadvisor
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start cadvisor
