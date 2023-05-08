#!/usr/bin/env bash


while true;
do
  current=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":51}' http://127.0.0.1:8545 | jq -r '.result.currentBlock' | tr -d '\n' |  xargs -0 printf "%d")
  timeStamp=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$current"'", false],"id":1}' localhost:8545  | jq -r ".result.timestamp" | tr -d '\n' |  xargs -0 printf "%d")
  dateStamp=$(date -d @"$timeStamp")

  localBlock=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":["latest", false],"id":1}' localhost:8545  | jq -r ".result" | tr -d '\n' |  xargs -0 printf "%d")
  localBlockTimestamp=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$localBlock"'", false],"id":1}' localhost:8545 | jq -r '.result.timestamp' | tr -d '\n' |  xargs -0 printf "%d")
  currentTime=$(date +%s)
  seconds=$(($currentTime - $localBlockTimestamp))
  hours=$(($seconds / 3600))
  minutes=$(($seconds / 60))

  highest=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":51}' http://127.0.0.1:8545 | jq -r '.result.highestBlock' | tr -d '\n' |  xargs -0 printf "%d")

  echo ""
  echo ":: Current Date ::"
  echo "$(date)"
  echo ""
  echo ":: Local Block Details ::"
  echo "Blocknumber: $current"
  echo "Current: $current"
  echo "Highest: $highest"
  echo "Left to sync: $(($highest - $current))"
  echo "Blocknumber Datestamp: $dateStamp"
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
