#!/usr/bin/env python3

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

logger = logging.getLogger('litecoinSweeper')

username = 'rpcuser'
password = 'rpcpass'

source_wallet = "main"
destination_address = "xx"

def get_balance(wallet_name):
    headers = {"content-type": "text/plain"}
    request_data = {"jsonrpc": "1.0", "id": "curl", "method": "getbalance", "params": []}
    request_url = "http://127.0.0.1:19332/wallet/{wallet}".format(wallet=wallet_name)
    response = requests.post(request_url, headers=headers, json=request_data, auth=(username, password))
    return float(response.json().get('result'))

def transfer(source_wallet, destination_address, value):
    headers = {"content-type": "text/plain"}
    request_data = {"jsonrpc": "1.0", "id": "curl", "method": "sendtoaddress", "params": [destination_address, value]}
    request_url = "http://127.0.0.1:19332/wallet/{wallet}".format(wallet=source_wallet)
    response = requests.post(request_url, headers=headers, json=request_data, auth=(username, password))
    return response.json().get('result')

balance = get_balance(source_wallet)

#print("Balance: {}".format(balance))

if balance > 1:
    value_to_send = (int(balance) - 1)
    timestamp = dt.now().strftime("%Y-%m-%dT%H:%M")
    txid = transfer(source_wallet, destination_address, value_to_send)
    logger.info("[{}] - LITECOIN - SENT - funds transferred as balance is {} and sent {} and received txid of {}".format(timestamp, balance, value_to_send, txid))
else:
    timestamp = dt.now().strftime("%Y-%m-%dT%H:%M")
    logger.info("[{}] - LITECOIN - SKIPPING -  balance is: {}".format(timestamp, balance))
