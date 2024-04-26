"""
  This is a example in python to send notifications using pushover.
"""

import os
import sys
import logging
import requests

pushover_app_token = os.getenv('PUSHOVER_APP_TOKEN')
pushover_user_key  = os.getenv('PUSHOVER_USER_KEY')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)

def send_notification(message):
    try:
        response = requests.post("https://api.pushover.net/1/messages.json", data = {
            "token": pushover_app_token,
            "user": pushover_user_key,
            "message": message
        })
        logging.info("notification sent")
        return response.json()
    except Exception as e:
        logging.error(f"Error: {e}")
        return None

message = "this is a test"
response = send_notification(message)
logging.info(response)
