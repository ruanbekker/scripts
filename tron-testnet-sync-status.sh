#!/usr/bin/env bash

currentBlock=$(curl -s "http://localhost:8332/wallet/getnowblock" | jq -r '.block_header.raw_data.number')
currentBlockTimestampInMs=$(curl -s -XPOST  http://127.0.0.1:8332/wallet/getblockbynum -d "{\"num\": $currentBlock}" | jq -r '.block_header.raw_data.timestamp')
currentTimeInMs=$(date +%s%N | cut -b1-13)
estimatedOutOfSyncInMs=$(($currentTimeInMs - $currentBlockTimestampInMs))
estimatedOutOfSyncInDays=$(($estimatedOutOfSyncInMs / 1000 / 60 / 60 / 24))

echo ":: Sync Status ::"
echo "BlockNumber: $currentBlock"
echo "BlockExplorer: https://nile.tronscan.org/#/block/$currentBlock"
echo "Minutes left: $(($estimatedOutOfSyncInMs / 1000 / 60 ))"
echo "Hours Left: $(($estimatedOutOfSyncInMs / 1000 / 60 / 60))"
echo "Days left: $estimatedOutOfSyncInDays"
echo ""
