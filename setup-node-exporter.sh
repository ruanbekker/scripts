#!/usr/bin/env bash
NODE_EXPORTER_USER="node_exporter"

# check if node exporter user exists
id -u ${NODE_EXPORTER_USER} &> /dev/null && EXIT_CODE=${?} || EXIT_CODE=${?}
if [ ${EXIT_CODE} == 1 ]
  then
    useradd --no-create-home --shell /bin/false ${NODE_EXPORTER_USER}
fi

if [ -d /usr/local/bin ] 
  then 
    echo "directory exists, using it"
    export BIN_DIRECTORY="/usr/local/bin"
  else 
    echo "directory does not exist, using one level back"
    export BIN_DIRECTORY="/usr/local"
fi

NODE_EXPORTER_VERSION="1.0.1"

wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter ${BIN_DIRECTORY}/
chown ${NODE_EXPORTER_USER}:${NODE_EXPORTER_USER} ${BIN_DIRECTORY}/node_exporter
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=${BIN_DIRECTORY}/node_exporter
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
