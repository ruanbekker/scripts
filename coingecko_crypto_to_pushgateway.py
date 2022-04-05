#!/usr/bin/env python3

"""
Docs: https://www.coingecko.com/en/api/documentation

All Coins: https://api.coingecko.com/api/v3/coins/list?include_platform=false
[
  {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin"
  },
  {
    "id": "cardano",
    "symbol": "ada",
    "name": "Cardano"
  },
  {
    "id": "ethereum",
    "symbol": "eth",
    "name": "Ethereum"
  }
]
"""

import requests

COINGECKO_API="https://api.coingecko.com/api/v3/simple/price"
PG_ENDPOINT="http://127.0.0.1:9091"

coin_ids="bitcoin,cardano,ethereum"

portfolio={
    'bitcoin': {'owned': 0.002, 'symbol': 'btc'},
    'cardano': {'owned': 2.5, 'symbol': 'ada'},
    'ethereum': {'owned': 0.02, 'symbol': 'eth'}
}

total_in_usd = []

def post_metric_to_pushgateway(coin, symbol, holding_amount, metric_name, metric_value):
    if coin == 'n/a':
        response = requests.post('{endpoint}/metrics/job/balances/type/total'.format(endpoint=PG_ENDPOINT), data='{_n} {_v}\n'.format(_n=metric_name, _v=metric_value))
    else:
        response = requests.post('{endpoint}/metrics/job/balances/coin/{coin}/symbol/{symbol}/holding_amount/{holding_amount}'.format(endpoint=PG_ENDPOINT, coin=coin, symbol=symbol, holding_amount=holding_amount), data='{_n} {_v}\n'.format(_n=metric_name, _v=metric_value))
    return response.status_code

def get_crypto_value_in_usd(coins):
    headers = {"accept": "application/json"}
    params = {"ids": coins, "vs_currencies": "usd"}
    response = requests.get(COINGECKO_API, params=params)
    return response.json()

def calculate_coin_in_usd(usd_value, crypto_amount):
    response = usd_value * crypto_amount
    return response

coindata = get_crypto_value_in_usd(coin_ids)
#print(coindata)

for c in coindata:
    coin_name = c
    coin_holding_amount = portfolio[c]['owned']
    symbol_name = portfolio[c]['symbol']
    value_in_usd = calculate_coin_in_usd(coindata[c]['usd'], portfolio[c]['owned'])
    total_in_usd.append(value_in_usd)
    #print("COIN: {coin}, OWNED: {owned}, VALUE: ${value}".format(coin=coin_name, owned=coin_holding_amount, value=value_in_usd))
    response = post_metric_to_pushgateway(coin_name, symbol_name, coin_holding_amount, 'coin_value_in_usd', value_in_usd)
    #print(response)

#print("Total Portfolio: {total}".format(total=sum(total_in_usd)))
totals = post_metric_to_pushgateway('n/a', 'n/a', 'n/a', 'crypto_value_in_usd', sum(total_in_usd))
#print(totals)
"""
response.json()
{'bitcoin': {'usd': 46753}, 'ethereum': {'usd': 3522.77}, 'cardano': {'usd': 1.2}}
"""

"""
for c in coindata:
    print("COIN: {coin}, USD: {usd}, OWNED: {owned}, RESULT: {result}".format(coin=c,usd=coindata[c]['usd'],owned=portfolio[c]['owned'], result=(coindata[c]['usd']) * (portfolio[c]['owned'])))

COIN: bitcoin, USD: 46753, OWNED: 0.002, RESULT: 93.506
...
"""
