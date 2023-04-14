#!/usr/bin/env bash
verification=$(curl -s -u "${rpcuser}:${rpcpass}" -d '{"jsonrpc": "1.0", "id": "curl", "method": "getblockchaininfo", "params": []}' -H 'content-type: text/plain;' http://127.0.0.1:18332/ | jq -r '.result.verificationprogress')
blockcount=$(curl -s -u "${rpcuser}:${rpcpass}" -d '{"jsonrpc": "1.0", "id": "curl", "method": "getblockcount", "params": []}' -H 'content-type: text/plain;' http://127.0.0.1:18332/ | jq -r '.result')
blockhash=$(curl -s -u "${rpcuser}:${rpcpass}" -d "{\"jsonrpc\": \"1.0\", \"id\": \"curl\", \"method\": \"getblockhash\", \"params\": [$blockcount]}" -H 'content-type: text/plain;' http://127.0.0.1:18332/ | jq -r '.result')
time=$(curl -s -u "${rpcuser}:${rpcpass}" -d '{"jsonrpc": "1.0", "id": "curl", "method": "getblock", "params": ["'"$blockhash"'"]}' -H 'content-type: text/plain;' http://127.0.0.1:18332/ | jq -r '.result.time')
echo $(((`date +%s`-$time)/60))
