#!/usr/bin/env python3

import os
import sys
import time
import requests
import argparse
from bs4 import BeautifulSoup

whitelisted_cryptocurrencies = ['bitcoin', 'ethereum', 'cardano']
whitelisted_fiatcurrencies = ['zar', 'usd']
cryptocurrency_acronymns = {'bitcoin': 'btc', 'ethereum': 'eth', 'cardano': 'ada'}

parser = argparse.ArgumentParser(description='cmc scraper')
parser.add_argument('-c', '--crypto', help='cryptocurrency name', required=True)
parser.add_argument('-f', '--fiat', help='fiatcurrency name', required=True)
args = parser.parse_args()

def scrape_coinmarketcap(cryptocurrency_name, fiatcurrency_name):
    if cryptocurrency_name not in whitelisted_cryptocurrencies or fiatcurrency_name not in whitelisted_fiatcurrencies:
        print(f"received a non supported exchange pair: {cryptocurrency_name}/{fiatcurrency_name}")
        sys.exit(1)
    crypto_acronymn = cryptocurrency_acronymns[cryptocurrency_name]
    URL = f"https://coinmarketcap.com/currencies/{cryptocurrency_name}/{crypto_acronymn}/{fiatcurrency_name}/"
    page = requests.get(URL)
    soup = BeautifulSoup(page.content, "html.parser")
    results = soup.find(id="__next")
    job_elements = results.find_all("div", class_="priceValue")
    results = []
    for job_element in job_elements:
        span_result = job_element.find("span").find_next(text=True)[1:-1]
        results.append(span_result)
    return results[-1]

exchanged_value = scrape_coinmarketcap(args.crypto, args.fiat)
print(f"{args.crypto} -> {args.fiat} = {exchanged_value}")
