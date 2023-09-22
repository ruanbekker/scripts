#!/usr/bin/env bash

NODE_EXPORTER_VERSION="1.5.0"

ned=$(mktemp -d)
pushd $ned
wget -qO - https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz | tar --strip 1 -zxv
sudo install -o root -g root -m 0755 node_exporter /usr/local/bin/node_exporter
popd 

sudo tee -a /etc/systemd/system/node_exporter.service > /dev/null << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
