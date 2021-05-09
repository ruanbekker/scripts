import requests
import json
"""
API Documentation: https://www.coingecko.com/en/api#explore-api
"""
GC_REQUEST_URL = "https://api.coingecko.com/api/v3/coins/markets"
GC_HEADERS = {"content-type": "application/json"}
GC_PARAMETERS = {
    "vs_currency": "usd",
    "order": "market_cap_desc",
    "per_page": 100,
    "page": 1,
    "sparkline": False,
    "price_change_percentage": "24h",
    "ids": "bitcoin,ethereum,ripple,dogecoin,cardano,safemoon,litecoin,polkadot,chainlink,vechain,tron,zilliqa,digibyte,siacoin"
}

current_prices = []

def format_outputs(coin_info):
    formatted_info = {}
    formatted_info['id'] = coin_info['id']
    formatted_info['symbol'] = coin_info['symbol']
    formatted_info['current_price'] = format(coin_info['current_price'], '.8f')
    formatted_info['market_cap'] = coin_info['market_cap']
    formatted_info['high_24h'] = format(coin_info['high_24h'], '.8f')
    formatted_info['low_24h'] = format(coin_info['low_24h'], '.8f')
    formatted_info['price_change_percentage_24h'] = coin_info['price_change_percentage_24h']
    formatted_info['circulating_supply'] = coin_info['circulating_supply']
    current_prices.append(formatted_info)
    return True

def request_prices():
    response = requests.get(GC_REQUEST_URL, headers=GC_HEADERS, params=GC_PARAMETERS).json()
    return response

retrieved_prices = request_prices()
for coin in retrieved_prices:
    format_outputs(coin)

print(json.dumps(current_prices, indent=2))
