if [[ -n "${ENVIRONMENT}" && "${ENVIRONMENT}" == "production" ]] 
then
    for attempt in $(seq 1 900); do
        curl -m 1 -f http://localhost:8080/healthcheck
        if [[ $? == 0 ]]
        then
            exit 0
        fi
        sleep 1
    done
else
    for attempt in $(seq 1 120) 
      do
        curl -m 1 -f http://localhost:8081/healthcheck
        if [[ $? == 0 ]]
        then
            exit 0
        fi
        sleep 1
    done
fi
