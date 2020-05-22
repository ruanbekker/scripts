#!/usr/bin/env bash
set -ex

# usage:
# curl .. | ETCD_NODE_1=127.0.0.1 ETCD_NODE_2=127.0.0.2 ETCD_NODE_3=127.0.0.3 bash -s -

LOKI_VERSION=1.5.0
LOKI_USER=loki
LOKI_ETCD_ENDPOINT_1="${ETCD_NODE_1:-127.0.0.1}"
LOKI_ETCD_ENDPOINT_2="${ETCD_NODE_2:-127.0.0.1}"
LOKI_ETCD_ENDPOINT_3="${ETCD_NODE_3:-127.0.0.1}"

if [[ ${LOKI_ETCD_ENDPOINT_1} == "127.0.0.1" && ${LOKI_ETCD_ENDPOINT_2} == "127.0.0.1" && ${LOKI_ETCD_ENDPOINT_3} == "127.0.0.1" ]]
then
	echo "you are trying to install loki with etcd, but no endpoints are provided"
  echo "usage:"
  echo "curl .. | ETCD_NODE_1=127.0.0.1 ETCD_NODE_2=127.0.0.2 ETCD_NODE_3=127.0.0.3 bash -s -"
	exit 1
fi

useradd -s /bin/nologin ${LOKI_USER}

wget https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
apt install unzip -y
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki
chmod +x /usr/local/bin/loki

mkdir -p /etc/loki
mkdir -p /var/lib/loki/{index,chunks}

cat > /etc/systemd/system/loki.service << EOF
[Unit]
Description=Loki
Wants=network-online.target
After=network-online.target

[Service]
User=${LOKI_USER}
Group=${LOKI_USER}
Type=simple
ExecStart=/usr/local/bin/loki -config.file /etc/loki/loki-config.yml

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/loki/loki-config.yml << EOF
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: etcd
        prefix: collectors/
        etcd:
          endpoints:
            - http://${LOKI_ETCD_ENDPOINT_1}:2379
            - http://${LOKI_ETCD_ENDPOINT_2}:2379
            - http://${LOKI_ETCD_ENDPOINT_3}:2379
          dial_timeout: 10s
          max_retries: 10
      heartbeat_timeout: 1m
      replication_factor: 3
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /var/lib/loki/index

  filesystem:
    directory: /var/lib/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOF

chown -R ${LOKI_USER}:${LOKI_USER} /etc/loki /var/lib/loki
systemctl daemon-reload
systemctl enable loki
systemctl restart loki
