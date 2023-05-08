#!/usr/bin/env bash


function getLastSyncedBlock(){
  curl -s -XPOST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":51}' http://127.0.0.1:8545 | jq -r '.result' | tr -d '\n' |  xargs -0 printf "%d"
}

function getHighestBlockNumber(){
  curl -s -XPOST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":51}' http://127.0.0.1:8545 | jq -r '.result.number' | tr -d '\n' |  xargs -0 printf "%d"
}

while true;
do
  currentBlockNumber=$(getLastSyncedBlock)
  highestBlockNumber=$(getHighestBlockNumber)
  timeStamp=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$currentBlockNumber"'", false],"id":1}' localhost:8545  | jq -r ".result.timestamp" | tr -d '\n' |  xargs -0 printf "%d")
  dateStamp=$(date -d @"$timeStamp")

  highestBlockTimestamp=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$highestBlockNumber"'", false],"id":1}' localhost:8545 | jq -r '.result.timestamp' | tr -d '\n' |  xargs -0 printf "%d")
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
  #echo "Block: $localBlock"
  echo ""
  echo ":: Time Left ::"
  echo "Seconds: $seconds"
  echo "Minutes: $minutes"
  echo "Hours: $hours"
  echo ""
  echo "-----------------------------------------"
  sleep 10

done
