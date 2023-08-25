#!/usr/bin/env bash

# Get the list of all namespaces and secrets
kubectl get secrets --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,SECRET:.metadata.name" --no-headers=true | grep -Ev '(sh.helm.release.v1|sealed-secrets-)' | while read -r line

do
  # Split the line into an array (namespace and secret name)
  IFS=' ' read -ra ARR <<< "$line"

  # Assign the namespace and secret name to variables
  namespace="${ARR[0]}"
  secret="${ARR[1]}"

  # Get the secret in yaml format and save it to a file
  kubectl get secret "$secret" --namespace="$namespace" -o yaml > "/opt/backups/kubernetes-objects/secrets/${namespace}_${secret}.yaml"
done
