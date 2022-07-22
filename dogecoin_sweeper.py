#!/usr/bin/env python3
# https://jcsaaddupuy.github.io/dogecoin-python/doc/dogecoinrpc.connection.html
import logging
import requests
from datetime import datetime as dt

logging.basicConfig(
    filename='/var/log/cryptonode.log',
    filemode='a',
    format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
    datefmt='%H:%M:%S',
    level=logging.INFO
)

#logging.info("Running Urban Planning")

logger = logging.getLogger('dogecoinSweeper')

username = 'rpcuser'
password = 'rpcpass'

source_wallet = ""
#source_wallet = "main"
destination_address = "xx"

tx_blockexplorer = "https://blockexplorer.one/dogecoin/testnet/tx"
adr_blockexplorer = "https://blockexplorer.one/dogecoin/testnet/address/{address}".format(address=destination_address)

def get_balance(wallet_name):
    headers = {"content-type": "text/plain"}
    request_data = {"jsonrpc": "1.0", "id": "curl", "method": "getbalance", "params": [wallet_name]}
    request_url = "http://127.0.0.1:44555/"
    response = requests.post(request_url, headers=headers, json=request_data, auth=(username, password))
    return float(response.json().get('result'))

def transfer(source_wallet, destination_address, value):
    headers = {"content-type": "text/plain"}
    request_data = {"jsonrpc": "1.0", "id": "curl", "method": "sendfrom", "params": [source_wallet, destination_address, value]}
    request_url = "http://127.0.0.1:44555/"
    response = requests.post(request_url, headers=headers, json=request_data, auth=(username, password))
    return response.json().get('result')

balance = get_balance(source_wallet)

print("Balance: {}".format(balance))

if balance > 20000:
    value_to_send = 10000
    #value_to_send = (int(balance) - 10)
    timestamp = dt.now().strftime("%Y-%m-%dT%H:%M")
    txid = transfer(source_wallet, destination_address, value_to_send)
    blockexplorer_url = "{url}/{txid}".format(url=tx_blockexplorer, txid=txid)
    logger.info("[{}] - DOGECOIN - SENT - funds transferred as balance is {} and sent {} and received txid of {} blockexplorer url {}".format(timestamp, balance, value_to_send, txid, blockexplorer_url))
else:
    timestamp = dt.now().strftime("%Y-%m-%dT%H:%M")
    logger.info("[{}] - DOGECOIN - SKIPPING -  balance is: {}".format(timestamp, balance))
