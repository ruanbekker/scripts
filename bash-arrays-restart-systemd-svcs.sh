#!/usr/bin/env bash
# description: check if services are running, and restarts it whenever in a non running state

my_services=(
  service1
  service2
  service3
  service4
)

for service in ${my_services[@]}
  do
    if [ "$(systemctl is-active $service)" != "active" ]
    then
      echo "service $service is not active, restarting it"
      systemctl restart $service
      echo "[$(date +%FT+%T)] service $service was stopped and restarted" >> /var/log/service-restarts.log
    fi
  done
