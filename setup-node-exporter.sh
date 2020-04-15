#!/usr/bin/env bash

NODE_EXPORTER_USER="node_exporter"

# check if node exporter user exists
id -u ${NODE_EXPORTER_USER} &> /dev/null && EXIT_CODE=${?} || EXIT_CODE=${?}
if [ ${EXIT_CODE} == 1 ]
  then
    useradd --no-create-home --shell /bin/false ${NODE_EXPORTER_USER}
fi

NODE_EXPORTER_VERSION="0.18.1"

wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown ${NODE_EXPORTER_USER}:${NODE_EXPORTER_USER} /usr/local/bin/node_exporter
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start node_exporter
