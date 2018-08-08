#!/usr/bin/env bash

restart_app(){
  APP_PID=$(ps aux | grep ' app-web' | grep -v grep | awk '{print $2}')
  echo "APP headphones are on, getting no response, restarting app-web"
  kill $APP_PID
}

APP_RESPONSE=$(curl -skL --connect-timeout 1 --max-time 2 -XGET https://localhost:443 1> /dev/null && echo "OK" || echo "ERROR")

if [ "$APP_RESPONSE" == "OK" ]
    then exit 0;
    else restart_app
fi
