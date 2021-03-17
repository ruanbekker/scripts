#!/bin/bash

# Checks TCP, if down, checks ICMP, then alert via Pushover

PUSHOVER_APP_TOKEN=""
PUSHOVER_USER_TOKEN=""
REMOTE_IP=""
REMOTE_HOST_NAME=""
REMOTE_PORT="22"

pushover(){
  APP_TOKEN='${PUSHOVER_APP_TOKEN}"
  USER_TOKEN="${PUSHOVER_USER_TOKEN}"
  TITLE="$1"
  MESSAGE="$2"
  curl 'https://api.pushover.net/1/messages.json' -X POST -d "token=$APP_TOKEN&user=$USER_TOKEN&message=\"$MESSAGE\"&title=$TITLE"
}

status=up

# check port to router
nc -vz -w 5 ${REMOTE_IP} ${REMOTE_PORT} &> /dev/null && TCP_EXIT_CODE=${?} || TCP_EXIT_CODE=${?}

if [ ${TCP_EXIT_CODE} == 1 ]
  then
    echo "remote port timed out, checking ping"
    # check icmp to remote ip
    ping -c 10 ${REMOTE_IP} &> /dev/null && ICMP_EXIT_CODE=${?} || ICMP_EXIT_CODE=${?}
    if [ ${ICMP_EXIT_CODE} == 1 ]
      then
        echo "icmp timed out, notifying"
        pushover ${REMOTE_HOST_NAME} "server down, tpc/${REMOTE_PORT} timed out"
      else
        echo "tcp timed out, but icmp works"
        pushover ${REMOTE_HOST_NAME} "port ${REMOTE_PORT} is down but icmp works"
    fi
  else
    # everything is fine
    echo "all good"
    exit 0
fi
