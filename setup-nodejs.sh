#!/bin/bash
# nvm ls-remote --lts
NODE_VERSION=v14.17.3
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
# PATH=$PATH:/root/.nvm/versions/node/$NODE_VERSION/bin
nvm install $NODE_VERSION
nvm alias default $NODE_VERSION
node -e "console.log('Running Node.js ' + process.version)"
