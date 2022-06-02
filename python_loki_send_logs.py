#!/usr/bin/env python3
# docs: https://grafana.com/docs/loki/latest/api/#post-lokiapiv1push
# screenshots: https://gist.github.com/ruanbekker/53f5147e9979812bbd9e2039f30d6a19

import requests
import time
import os

# variables
LOKI_USERNAME = os.environ['LOKI_USERNAME']
LOKI_PASSWORD = os.environ['LOKI_PASSWORD']
LOKI_ENDPOINT = "https://loki-api.example.com/loki/api/v1/push"

def generate_log_message(message):
    headers = {"content-type":"application/json"}
    data = {
        "streams": [{
            "stream": { "job": "python-requests", "env": "test", "level": "info" },
            "values": [ [ time.time_ns(), message ] ]
        }]
    }
    response = requests.post(LOKI_ENDPOINT, headers=headers, json=data, auth=(LOKI_USERNAME, LOKI_PASSWORD))
    return response.status_code

response = generate_log_message("this is a test")
print(response)
