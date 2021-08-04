#!/usr/bin/env python3
import random
import requests
import json

pushgateway_endpoint="http://127.0.0.1:9091"
pushgateway_username=""
pushgateway_password=""

def get_metrics():
    cpu_value = random.randint(10,20)
    return cpu_value

def post_metric_to_pushgateway(instance_name, metric_category, metric_name, metric_value):
    request_url = '{endpoint}/metrics/job/pythontest/server/{server}/category/{category}'.format(endpoint=pushgateway_endpoint, server=instance_name, category=metric_category)
    response = requests.post(request_url, data='{_n} {_v}\n'.format(_n=metric_name, _v=metric_value), auth=(pushgateway_username, pushgateway_password))
    return response.status_code

# get metric values
cpu_value = get_metrics()

# emit balance metric to pushgateway and let prometheus scrape pushgateway to ingest into prometheus tsdb
server1_status = post_metric_to_pushgateway('server1', 'node-metrics', 'cpu_percentage', cpu_value)

# return response to stdout
payload = {"server1": server1_status}
print(json.dumps(payload, indent=2, default=str))
