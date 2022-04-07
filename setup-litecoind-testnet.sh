#!/usr/bin/env bash

# This installs a litecoin fullnode on the testnet chain

CRYPTO_USER="litecoin"
CRYPTO_NAME="litecoin"
CRYPTO_VERSION="0.18.1"
CRYPTO_USER="litecoinrpc"
CRYPTO_PASS="$(openssl rand -hex 10)"

# check if crypto user exists
id -u ${CRYPTO_USER} &> /dev/null && EXIT_CODE=${?} || EXIT_CODE=${?}
if [ ${EXIT_CODE} == 1 ]
  then
    useradd --no-create-home --shell /bin/false ${CRYPTO_USER}
fi

mkdir -p /blockchain/${CRYPTO_NAME}/data
mkdir -p /blockchain/${CRYPTO_NAME}/scripts
mkdir -p /usr/local/${CRYPTO_NAME}/0.18.1/bin
mkdir -p /home/${CRYPTO_USER}/.${CRYPTO_NAME}
mkdir -p /etc/${CRYPTO_NAME}
mkdir -p /var/log/${CRYPTO_NAME}
touch /var/log/${CRYPTO_NAME}/wallet-notify.log

cd /tmp
wget https://download.${CRYPTO_NAME}.org/${CRYPTO_NAME}-${CRYPTO_VERSION}/linux/${CRYPTO_NAME}-${CRYPTO_VERSION}-x86_64-linux-gnu.tar.gz
tar -xf ${CRYPTO_NAME}-${CRYPTO_VERSION}-x86_64-linux-gnu.tar.gz
mv ${CRYPTO_NAME}-${CRYPTO_VERSION}/bin/${CRYPTO_NAME}* /usr/local/${CRYPTO_NAME}/${CRYPTO_VERSION}/bin/
rm -f ${CRYPTO_NAME}-${CRYPTO_VERSION}-x86_64-linux-gnu.tar.gz

ln -s /usr/local/${CRYPTO_NAME}/${CRYPTO_VERSION} /usr/local/${CRYPTO_NAME}/current
ln -s /etc/${CRYPTO_NAME}/${CRYPTO_NAME}-testnet.conf /home/${CRYPTO_USER}/.${CRYPTO_NAME}/${CRYPTO_NAME}.conf

cat > /etc/${CRYPTO_NAME}/${CRYPTO_NAME}-testnet.conf << EOF
datadir=/blockchain/${CRYPTO_NAME}/data
printtoconsole=1
onlynet=ipv4
rpcallowip=127.0.0.1
rpcuser=${CRYPTO_USER}
rpcpassword=${CRYPTO_PASS}
rpcclienttimeout=300
testnet=1
prune=2500
walletnotify=/blockchain/${CRYPTO_NAME}/scripts/notify.sh %s %w
[test]
rpcbind=127.0.0.1
rpcport=19332
EOF

cat > /blockchain/${CRYPTO_NAME}/scripts/notify.sh << EOF
#!/usr/bin/env bash
echo "[\$(date +%FT%T)] \$1 \$2" >> /var/log/${CRYPTO_NAME}/wallet-notify.log
EOF

cat > /etc/profile.d/${CRYPTO_NAME}d.sh << EOF
export PATH=\$PATH:/usr/local/litecoin/current/bin
EOF

cat > /etc/systemd/system/${CRYPTO_NAME}d.service << EOF
[Unit]
Description=${CRYPTO_NAME} testnet
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=${CRYPTO_USER}
Group=${CRYPTO_USER}
WorkingDirectory=/blockchain/${CRYPTO_NAME}/data
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/${CRYPTO_NAME}/current/bin/${CRYPTO_NAME}d -conf=/home/${CRYPTO_USER}/.${CRYPTO_NAME}/${CRYPTO_NAME}.conf
[Install]
WantedBy=multi-user.target
EOF

chmod +x /blockchain/${CRYPTO_NAME}/scripts/notify.sh
chmod +x /etc/profile.d/${CRYPTO_NAME}d.sh
chown -R ${CRYPTO_USER}:${CRYPTO_USER} /blockchain/${CRYPTO_NAME}
chown -R ${CRYPTO_USER}:${CRYPTO_USER} /home/${CRYPTO_USER}
chown -R ${CRYPTO_USER}:${CRYPTO_USER} /etc/${CRYPTO_NAME}
chown -R ${CRYPTO_USER}:${CRYPTO_USER} /var/log/${CRYPTO_NAME}

systemctl daemon-reload
systemctl enable ${CRYPTO_NAME}d
systemctl start ${CRYPTO_NAME}d

sleep 5
curl -s -u "${CRYPTO_USER}:${CRYPTO_PASS}" -d '{"jsonrpc": "1.0", "id": "curl", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://127.0.0.1:19332/  | python3 -m json.tool

echo "User: ${CRYPTO_USER}"
echo "Pass: ${CRYPTO_PASS}"
echo "Endpoint: http://127.0.0.1:19332"


