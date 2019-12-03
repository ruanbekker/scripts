#!/usr/bin/env bash

# Description:
# Bash Script for put/get secrets to/from Vault
#
# Get:
# ./vault_secrets.sh get secret/tmp/hostname
#
# Put:
# ./vault_secrets.sh put secret/tmp/hostname app.example.com

# global environment values
export VAULT_HOSTNAME=${VAULT_HOSTNAME}
export VAULT_TOKEN=${VAULT_TOKEN}

# check if variables are provided
if [ -z ${VAULT_HOSTNAME} ] || [ -z ${APP_TOKEN} ]
then 
	echo "Requires VAULT_HOSTNAME and APP_TOKEN env variables"
  exit 1
fi

# check if args is passed
if [[ $# -eq 0 ]]
then
    echo ""
    echo "Action required:"
    echo "eg: $0 list params"
    echo "eg: $0 get params"
    echo "eg: $0 put params"
    echo ""
    exit 1
fi

# functions
put_secret(){
  curl -s -XPOST -H "X-Vault-Token: ${VAULT_TOKEN}" -d '{"'"${SECRET_KEY}"'": "'"$SECRET_VALUE"'"}' https://${VAULT_HOSTNAME}/v1/${SECRET}
}

get_secret(){
  curl -s -XGET -H "X-Vault-Token: ${VAULT_TOKEN}" https://${VAULT_HOSTNAME}/v1/${SECRET} | jq -r ".data.${SECRET_KEY}"
}

list_secrets(){
  curl -s -XLIST -H "X-Vault-Token: ${VAULT_TOKEN}" https://${REQUEST_URL}/v1/${SECRET} | jq -r ".data"
}

# main script
if [ ${1} == "help" ]
then
	echo ""
	echo "Secrets Management Help:"
	echo "========================"
	echo "${0} list secret/application-name"
	echo "${0} put secret/application-name/hostname app.example.com"
	echo "${0} get secret/application-name/hostname"
	echo ""
	exit 0
	
elif [ ${1} == "list" ]
then
	if [[ $# -ne 2 ]]
	then
		echo ""
		echo "ListSecrets requires the path to include the keys you want to list"
		echo "usage: $0 list secret/application-name"
		echo ""
		exit 1
	fi

	SECRET=${2}
	echo "List secrets for ${SECRET}"
	list_secrets ${SECRET}


elif [ ${1} == "put" ] 
then
	if [[ $# -ne 3 ]]
        then
		echo ""
                echo "PutSecret requires the key and value to retrieve the secret"
                echo "usage: $0 put secret/application-name/secret-key secret-value"
                echo ""
                exit 1
	fi

	SECRET=${2}
	SECRET_KEY=$(echo ${SECRET} | rev | cut -d'/' -f1 | rev)
	SECRET_VALUE=${3}
	put_secret ${SECRET} ${SECRET_VALUE}
	echo "Secret: ${SECRET} has been written"
	exit 0

elif [ ${1} == "get" ]
then
	if [[ $# -ne 2 ]]
	then 
		echo ""
                echo "GetSecret requires the key to retrieve the secret"
                echo "usage: $0 get secret/application-name/secret-key"
                echo ""
                exit 1
	fi
	
	SECRET=${2}
	SECRET_KEY=$(echo ${SECRET} | rev | cut -d'/' -f1 | rev)
	get_secret ${SECRET}

else
	echo "require: put/get as a parameter"
	exit 1

fi
