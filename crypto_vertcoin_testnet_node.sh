#!/usr/bin/env bash

wget https://github.com/vertcoin-project/vertcoin-core/releases/download/0.18.0-rc1/vertcoind-v0.18.0-rc1-arm-linux-gnueabihf.zip
unzip vertcoind-v0.18.0-rc1-arm-linux-gnueabihf.zip
rm -rf vertcoind-v0.18.0-rc1-arm-linux-gnueabihf.zip

sudo mv vertcoin* /usr/bin/
sudo mkdir /etc/vertcoin
sudo mkdir -p /blockchain/vertcoin/data
sudo chown -R pi:pi /etc/vertcoin
sudo chown -R pi:pi /blockchain/vertcoin

cat > vertcoin.conf << EOF
datadir=/blockchain/vertcoin/data
printtoconsole=1
rpcallowip=127.0.0.1
rpcuser=${RPC_USER:-rpcuser}
rpcpassword=${RPC_PASSWORD:-$(openssl rand -hex 24)}
testnet=1
prune=2500
[test]
rpcbind=127.0.0.1
rpcport=15888
EOF

mv vertcoin.conf /etc/vertcoin/

cat > vertcoind.service << EOF
[Unit]
Description=Vertcoin Testnet
After=network.target

[Service]
User=$(whoami)
Group=$(whoami)
WorkingDirectory=/blockchain/vertcoin/data
Type=simple
ExecStart=/usr/bin/vertcoind -conf=/etc/vertcoin/vertcoin.conf

[Install]
WantedBy=multi-user.target
EOF

sudo mv vertcoind.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo systemctl start vertcoind
sudo systemctl status vertcoind
sudo journalctl -fu vertcoind
