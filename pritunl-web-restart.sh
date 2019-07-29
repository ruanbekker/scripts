#!/usr/bin/env bash

restart_pritunl(){
  PRITUNL_PID=$(ps aux | grep ' pritunl-web' | grep -v grep | awk '{print $2}')
  echo "Request to Pritunl-Web Timed Out. Restarting Printunl-Web Process"
  kill $PRITUNL_PID
}

PRITUNL_RESPONSE=$(curl -skL --connect-timeout 1 --max-time 2 -XGET https://localhost:443 1> /dev/null && echo "OK" || echo "ERROR")

if [ "$PRITUNL_RESPONSE" == "OK" ]
    then exit 0;
    else restart_pritunl
fi
