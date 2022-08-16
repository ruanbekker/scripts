#!/usr/bin/env bash
set -ex

CRYPTO_USER=crypto
CRYPTO_VERSION=0.21.2

useradd -s /bin/bash -m ${CRYPTO_USER}

mkdir -p /blockchain/bitcoin/{data,config,bin}

wget https://bitcoincore.org/bin/bitcoin-core-${CRYPTO_VERSION}/bitcoin-${CRYPTO_VERSION}-x86_64-linux-gnu.tar.gz
tar -xvf bitcoin-${CRYPTO_VERSION}-x86_64-linux-gnu.tar.gz
mv bitcoin-${CRYPTO_VERSION}/bin/bitcoin* /blockchain/bitcoin/bin/
rm -rf bitcoin-${CRYPTO_VERSION}

cat > /blockchain/bitcoin/config/bitcoin.conf << EOF
datadir=/blockchain/bitcoin/data
testnet=1
printtoconsole=1
rpcuser=bitcoinrpc
rpcpassword=testnetpass
rpcbind=0.0.0.0
rpcallowip=127.0.0.1
prune=1000
txconfirmtarget=2
[test]
rpcbind=0.0.0.0
rpcport=18332
EOF

cat > /etc/systemd/system/bitcoind.service << EOF
[Unit]
Description=Bitcoind
After=network.target

[Service]
User=$CRYPTO_USER
Group=$CRYPTO_USER
WorkingDirectory=/blockchain/bitcoin/data

Type=simple
ExecStart=/blockchain/bitcoin/bin/bitcoind \
  -conf=/blockchain/bitcoin/config/bitcoin.conf \
  -daemon=0

[Install]
WantedBy=multi-user.target
EOF

chown -R $CRYPTO_USER:$CRYPTO_USER /blockchain/bitcoin
sudo systemctl daemon-reload
