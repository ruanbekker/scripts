#!/usr/bin/env bash

# This script monitors the block number of a ethereum node on the sepolia testnet
# and indicates if its in initial sync or not

# The output:
# :: sync status ::
# initial-sync: true
# 
# :: current block ::
# current timestamp: 1699780814 / 2023-11-12 09:20:14
# current block: 3430736
# current highest block: 4675413 (at boot time)
# blockexplorer url: https://sepolia.etherscan.io/block/3430736
#
# :: block details ::
# current block result count: 23
# current block transactions count: 14
# current block withdrawals count: 16
# current block gas baseper: 7
# current block gas limit: 30000000
# current block gas used: 859047
# current block miner: 0x9a6034c84cd431409ac1a35278c7da36ffda53e5
# current block nonce: 0
# current block parenth hash: 0x23253ee32868c94be9a1d7918ec8001053bfb08cbb4566417285ab97c8b5dbeb
# current block extra data: 0xd883010b06846765746888676f312e32302e33856c696e7578
# current block withdrawalsRoot: 0xe1d17fdfe04fff98ec2ebafea303916f0c99a8a00f1fd83e4ddc81d784143d36
# current block transactionsRoot: 0xe59463a7d681c766d2a7a9a116fbbdf769d14c3ca9eaddf76f6cccca126812c0
# current block timestamp: 1683381504 / 2023-05-06 13:58:24
# current block timestamp delta: 273321 minutes
# current block delta: 1244677


# :: ENVIRONMENT VARIABLES ::"
ETH_NETWORK="sepolia"
ETH_BLOCKEXPLORER_URL="https://sepolia.etherscan.io"
EXTRA_DETAILS=false

# :: FUNCTIONS :: #
function convert_hex(){
  tr -d '\n' | xargs -0 printf "%d"
}

# :: PROCESSING :: #

# write json file
curl -s -X POST -H 'Content-Type: application/json'  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://127.0.0.1:8545 | jq -r '.' > /tmp/result.json

# check if result in syncing
result_count=$(cat /tmp/result.json | jq -r '.result | length')
if [[ $result_count -gt 0 ]]
then
  initial_sync_status="true";
  current_block=$(cat /tmp/result.json | jq -r '.result.currentBlock' | convert_hex)
  current_block_raw=$(cat /tmp/result.json | jq -r '.result.currentBlock')
  current_highest_block=$(cat /tmp/result.json | jq -r '.result.highestBlock' | convert_hex )
else
  initial_sync_status="false"
  curl -s -X POST -H 'Content-Type: application/json'  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://127.0.0.1:8545 | jq -r '.' > /tmp/result.json
  current_highest_block=$(cat /tmp/result.json | jq -r '.result' | convert_hex)
fi

# current block
current_timestamp=$(date +%s)
current_timestamp_formatted=$(date -d "@$current_timestamp" "+%Y-%m-%d %H:%M:%S")
# -> using eth_getBlockByNumber with the block or latest yields the same results as its the latest number of the local chain
# current_block_details=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$current_block_raw"'", false],"id":1}' localhost:8545 | jq -r '.' > /tmp/result_block.json)
current_block_details=$(curl -s -H "Content-type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8545 | jq -r '.' > /tmp/result_block.json)
current_block_result_count=$(cat /tmp/result_block.json | jq -r '.result | length')
current_block_transactions_count=$(cat /tmp/result_block.json | jq -r '.result.transactions | length')
current_block_withdrawals_count=$(cat /tmp/result_block.json | jq -r '.result.withdrawals | length')
current_block_transactions_value=$(cat /tmp/result_block.json | jq -r '.result.transactions')
current_block_withdrawals_value=$(cat /tmp/result_block.json | jq -r '.result.withdrawals[] | "address=\(.address), amount=\(.amount)"' | awk -F ', ' '{split($2, amount, "="); printf "  %s, amount=%d\n", $1, amount[2]}')
current_block_gas_used=$(cat /tmp/result_block.json | jq -r '.result.gasUsed' | convert_hex)
current_block_gas_limit=$(cat /tmp/result_block.json | jq -r '.result.gasLimit' | convert_hex)
current_block_url="${ETH_BLOCKEXPLORER_URL}/block/$current_block"
current_block_miner=$(cat /tmp/result_block.json | jq -r '.result.miner')
current_block_nonce=$(cat /tmp/result_block.json | jq -r '.result.nonce' | convert_hex)
current_block_parentHash=$(cat /tmp/result_block.json | jq -r '.result.parentHash')
current_block_withdrawals_count=$(cat /tmp/result_block.json | jq -r '.result.withdrawals | length')
current_block_withdrawals_value=$(cat /tmp/result_block.json | jq -r '.result.withdrawals[] | "address=\(.address), amount=\(.amount)"' | awk -F ', ' '{split($2, amount, "="); printf "  %s, amount=%d\n", $1, amount[2]}')
current_block_baseFeePerGas=$(cat /tmp/result_block.json | jq -r '.result.baseFeePerGas' | convert_hex)
current_block_extraData=$(cat /tmp/result_block.json | jq -r '.result.extraData')
current_block_transactionsRoot=$(cat /tmp/result_block.json | jq -r '.result.transactionsRoot')
current_block_withdrawalsRoot=$(cat /tmp/result_block.json | jq -r '.result.withdrawalsRoot')
current_block_timestamp=$(cat /tmp/result_block.json | jq -r '.result.timestamp' | convert_hex)
current_block_timestamp_formatted=$(date -d "@$current_block_timestamp" "+%Y-%m-%d %H:%M:%S")
current_block_delta=$((current_timestamp - current_block_timestamp))
current_block_delta_minutes=$((current_block_delta / 60))

# if initial sync is happening we will get the current local block and the highest block of node start time
# we can use this to identify how many blocks it still need to sync, once the initial sync is done, this will become false
# and then we can use eth_blockNumber
echo ""
echo ":: sync status ::"
echo "initial-sync: $initial_sync_status"
echo ""
echo ":: current block ::"
echo "current timestamp: $current_timestamp / $current_timestamp_formatted"
echo "current block: $current_block"
# if the sync process is in progress the highest block was determined at boot time
if [[ "${initial_sync_status}" == "true" ]]
then
  echo "current highest block: $current_highest_block (at boot time)"
else
  echo "current highest block: $current_highest_block"
fi
echo "blockexplorer url: $current_block_url"
echo ""
echo ":: block details ::"
echo "current block result count: $current_block_result_count"
# echo "current block transactions: $current_block_transactions"
echo "current block transactions count: $current_block_transactions_count"
echo "current block withdrawals count: $current_block_withdrawals_count"
if [[ "${EXTRA_DETAILS}" == "true" ]]
then
  echo "current block transactions: $current_block_transactions_value"
  echo -e "current block withdrawals: \n$current_block_withdrawals_value"
fi
echo "current block gas baseper: $current_block_baseFeePerGas"
echo "current block gas limit: $current_block_gas_limit"
echo "current block gas used: $current_block_gas_used"
echo "current block miner: $current_block_miner"
echo "current block nonce: $current_block_nonce"
echo "current block parenth hash: $current_block_parentHash"
echo "current block extra data: $current_block_extraData"
echo "current block withdrawalsRoot: $current_block_withdrawalsRoot"
echo "current block transactionsRoot: $current_block_transactionsRoot"
echo "current block timestamp: $current_block_timestamp / $current_block_timestamp_formatted"
echo "current block timestamp delta: $current_block_delta_minutes minutes"
echo "current block delta: $((current_highest_block - current_block))"
echo ""
