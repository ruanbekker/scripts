#!/bin/bash
set -ex

# check if args is passed
if [[ $# -eq 0 ]] ; then
    echo "secret path and value needed, eg: $0 secret/tmp/hostname app.example.com"
    exit 0
fi

VAULT_TOKEN=${VAULT_TOKEN}
REQUEST_URL=${REQUEST_URL}
SECRET=$1
SECRET_KEY=$(echo ${SECRET} | rev | cut -d'/' -f1 | rev)
SECRET_VALUE=$2

curl -s -XPOST -H "X-Vault-Token: ${VAULT_TOKEN}" -d '{"'"${SECRET_KEY}"'": "'"$SECRET_VALUE"'"}' https://${REQUEST_URL}/v1/${SECRET}
