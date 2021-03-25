#!/usr/bin/bash

get_secrets(){
  LOKI_USERNAME="$(aws --region eu-west-1 ssm get-parameter --name '/devops/tools/LOKI_USERNAME' | jq -r '.Parameter.Value')"
  LOKI_PASSWORD="$(aws --region eu-west-1 ssm get-parameter --name '/devops/tools/LOKI_PASSWORD' | jq -r '.Parameter.Value')"
  LOKI_HOSTNAME="$(aws --region eu-west-1 ssm get-parameter --name '/devops/tools/LOKI_HOSTNAME' | jq -r '.Parameter.Value')"
}

while [ -z $LOKI_USERNAME ] || [ -z $LOKI_PASSWORD ] || [ -z $LOKI_HOSTNAME ]
    do
        echo getting missing secrets
        get_secrets
        sleep 1
    done
    echo "got the secrets"
