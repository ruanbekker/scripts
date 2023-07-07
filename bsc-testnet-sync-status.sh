#!/usr/bin/env bash

while true;
do
  curl -s -XPOST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://127.0.0.1:8575 | jq -r '.result' > /tmp/block.json
  currentblockraw=$(cat /tmp/block.json | jq -r '.currentBlock')
  currentblock=$(cat /tmp/block.json | jq -r '.currentBlock' | tr -d '\n' |  xargs -0 printf "%d")
  highestblock=$(cat /tmp/block.json | jq -r '.highestBlock' | tr -d '\n' |  xargs -0 printf "%d")
  currenttime=$(date +%s)
  currentblocktime=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$currentblockraw"'", false],"id":1}' localhost:8575 | jq -r '.result.timestamp' | tr -d '\n' |  xargs -0 printf "%d")

  echo ":: Date: $(date +%FT%H:%m:%S) ::"
  echo "Blocks left to sync:  $(($highestblock - $currentblock))"
  echo "Current block number: $currentblock"
  echo "Blockexplorer:        https://testnet.bscscan.com/block/$currentblock"
  echo "Time left to sync:    $(($(($currenttime - $currentblocktime)) / 3600))h"
  echo ":: ------------------------- ::"
  sleep 10
done
