#!/usr/bin/env bash

interval=${1:-5}

function getLastSyncedBlockHex(){
  curl -s -XPOST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://127.0.0.1:8545 | jq -r '.result'
}

function getHighestBlockNumberHex(){
  curl -s -XPOST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' http://127.0.0.1:8545 | jq -r '.result.number'
}

while true;
do
  currentBlockHex=$(getLastSyncedBlockHex)
  highestBlockHex=$(getHighestBlockNumberHex)
  currentBlockNumber=$(echo $currentBlockHex | tr -d '\n' |  xargs -0 printf "%d")
  highestBlockNumber=$(echo $highestBlockHex | tr -d '\n' |  xargs -0 printf "%d")
  timeStamp=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$currentBlockHex"'", false],"id":1}' localhost:8545  | jq -r ".result.timestamp" | tr -d '\n' |  xargs -0 printf "%d")
  dateStamp=$(date -d @"$timeStamp")
  #macDateStamp=$(date -r $timestamp)

  highestBlockTimestamp=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$highestBlockHex"'", false],"id":1}' localhost:8545 | jq -r '.result.timestamp' | tr -d '\n' |  xargs -0 printf "%d")
  currentTime=$(date +%s)
  seconds=$(($currentTime - $highestBlockTimestamp))
  hours=$(($seconds / 3600))
  minutes=$(($seconds / 60))

  echo ""
  echo ":: Current Date ::"
  echo "$(date)"
  echo ""
  echo ":: Block Details ::"
  echo "CurrentBlockNumber: $currentBlockNumber"
  echo "HighestBlockNumber: $highestBlockNumber"
  echo "Blocks Left to sync: $(($highestBlockNumber - $currentBlockNumber))"
  echo "Current Blocknumber Datestamp: $dateStamp"
  echo ""
  echo ":: Time Left ::"
  echo "Seconds: $seconds"
  echo "Minutes: $minutes"
  echo "Hours: $hours"
  echo ""
  echo "-----------------------------------------"
  sleep $interval

done
