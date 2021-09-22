#!/usr/bin/env bash
set -ex

CRYPTO_NAME="dogecoin"
VERSION="1.14.4"
ARCH="x86_64"
TARBALL_URL="https://github.com/${CRYPTO_NAME}/${CRYPTO_NAME}/releases/download/v${VERSION}/${CRYPTO_NAME}-${VERSION}-${ARCH}-linux-gnu.tar.gz"
wget ${TARBALL_URL}

sudo mkdir -p /opt/${CRYPTO_NAME}/${VERSION}
sudo mkdir -p /blockchain/${CRYPTO_NAME}/data
sudo mkdir -p /etc/${CRYPTO_NAME}

sudo tar -xvf ${CRYPTO_NAME}-${VERSION}-${ARCH}-linux-gnueabihf.tar.gz -C /opt/${CRYPTO_NAME}/${VERSION} --strip-components=1
sudo ln -s /opt/${CRYPTO_NAME}/${VERSION} /opt/${CRYPTO_NAME}/current

sudo chown -R "$(whoami):$(whoami)" /blockchain
sudo chown -R "$(whoami):$(whoami)" /opt/${CRYPTO_NAME}
sudo chown -R "$(whoami):$(whoami)" /etc/${CRYPTO_NAME}

cat > ${CRYPTO_NAME}.conf << EOF
datadir=/blockchain/${CRYPTO_NAME}/data
printtoconsole=1
rpcallowip=127.0.0.1
rpcuser=${RPC_USER:-rpcuser}
rpcpassword=${RPC_PASSWORD:-$(openssl rand -hex 24)}
testnet=1
prune=2500
[test]
rpcbind=127.0.0.1
rpcport=44555
EOF

cat > ${CRYPTO_NAME}d.service <<  EOF
[Unit]
Description=${CRYPTO_NAME} Testnet
After=network.target

[Service]
User=$(whoami)
Group=$(whoami)
WorkingDirectory=/blockchain/${CRYPTO_NAME}/data
Type=simple
ExecStart=/opt/${CRYPTO_NAME}/current/bin/${CRYPTO_NAME}d -conf=/etc/${CRYPTO_NAME}/${CRYPTO_NAME}.conf

[Install]
WantedBy=multi-user.target
EOF

sudo mv ${CRYPTO_NAME}.conf /etc/${CRYPTO_NAME}/${CRYPTO_NAME}.conf
sudo mv ${CRYPTO_NAME}d.service /etc/systemd/system/
export PATH=$PATH:/opt/${CRYPTO_NAME}/current/bin

sudo systemctl daemon-reload
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo systemctl start ${CRYPTO_NAME}d
sleep 10
sudo systemctl status ${CRYPTO_NAME}d
