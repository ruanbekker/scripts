#!/bin/bash

for attempt in $(seq 1 360)
  do
    curl -m 1 -f http://localhost:18080/healthcheck
    if [[ $? == 0 ]]
      then
        echo "service is up"
        exit 0
    fi
    sleep 1
done
echo "service timed out after several attempts"
exit 1
