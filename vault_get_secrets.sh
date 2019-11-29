#!/bin/bash

# check if args is passed
if [[ $# -eq 0 ]] ; then
    echo "secret path needed, eg: $0 secret/tmp/hostname"
    exit 0
fi

VAULT_TOKEN=${VAULT_TOKEN}
REQUEST_URL=${VAULT_HOSTNAME}
SECRET=$1
SECRET_KEY=$(echo ${SECRET} | rev | cut -d'/' -f1 | rev)

curl -s -XGET -H "X-Vault-Token: ${VAULT_TOKEN}" https://${REQUEST_URL}/v1/${SECRET} | jq -r ".data.${SECRET_KEY}"
