#!/usr/bin/env bash

#############################################################################
## Installs KinD, then deploys Nginx Ingress, Gitea and ArgoCD using Helm. ##
## Runs on Linux and requires (net-tools, docker, kind, helm, kubectl      ##
#############################################################################

# sudo apt update; sudo apt install jq net-tools
# curl https://raw.githubusercontent.com/ruanbekker/scripts/master/devops-bootstrap-workspace.sh | bash

# Inspired by: https://gist.github.com/iul1an/932ec69b8e3def362aaa0f3358170ca9

set -exuo pipefail

# create cluster

if [[ $(kind get clusters) != "kind" ]]; then
  cat <<EOF | kind create cluster --config=-
---
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: $(pwd)/mnt
    containerPath: /mnt
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
fi

# Ingress IP
INGRESS_IP=$(ip addr show $(ip route get 1.2.3.4 | grep -oP 'dev \K\S+') | grep -w 'inet' | awk '{print $2}' | cut -d/ -f1)
INGRESS_DOMAIN="${INGRESS_IP}.nip.io"

# Install Ingress Nginx
echo
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
sleep 15
kubectl wait --namespace ingress-nginx  --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

# add helm charts repos
echo
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# install Gitea
GITEA_HOST="gitea.${INGRESS_DOMAIN}"
GITEA_USERNAME=gitea_admin
GITEA_PASSWORD=gitea_admin
echo
cat <<EOF | helm upgrade --install gitea gitea-charts/gitea --wait --create-namespace --namespace=gitea --values=-
ingress:
  enabled: true
  hosts:
  - host: "${GITEA_HOST}"
    paths:
      - path: /
        pathType: Prefix

postgresql:
  enabled: true
postgresql-ha:
  enabled: false

gitea:
  admin:
    username: ${GITEA_USERNAME}
    password: ${GITEA_PASSWORD}
extraVolumes:
- name: host-mount
  hostPath:
    path: /mnt
extraContainerVolumeMounts:
- name: host-mount
  mountPath: /data/git/gitea-repositories
initPreScript: mkdir -p /data/git/gitea-repositories/gitea_admin
EOF

## configure Gitea
## inspiration: https://cloudpirates.medium.com/local-prototyping-of-argocd-manifests-with-minikube-and-gitea-a8eb20a0f2d3
sleep 10
echo

# Wait for Gitea to become available
url="http://${GITEA_HOST}"
max_attempts=10
delay=3
attempt=1

while [ $attempt -le $max_attempts ]
do
  echo "Attempt #$attempt..."
  # Send request and check response
  response=$(curl -s -o /dev/null -w "%{http_code}" $url)
  # Check if the response is 200
  if [ "$response" -eq 200 ]; then
    echo "Successfully received 200 response."
    break
  else
    echo "Response was $response, not 200. Trying again in $delay seconds..."
  fi
  # Increment attempt counter
  attempt=$((attempt + 1))
  if [[ $attempt == $max_attempts ]]; then
    echo max attempt reached
    exit 1
  fi

  # Wait before next attempt
  sleep $delay
done

# initialize directories
if [[ ! -d mnt/gitea_admin/local-repo.git ]] ; then
  mkdir -p mnt/gitea_admin/local-repo.git
  pushd mnt/gitea_admin/local-repo.git
  git init --bare
  popd
fi

curl -v -s -XPOST -H "Content-Type: application/json" -k -u "${GITEA_USERNAME}:${GITEA_PASSWORD}" \
  --url "http://${GITEA_HOST}/api/v1/admin/unadopted/gitea_admin/local-repo"
echo
curl -v -s -XPATCH -H "Content-Type: application/json" -k -d '{"private": false}' -u "${GITEA_USERNAME}:${GITEA_PASSWORD}" \
  --url "http://${GITEA_HOST}/api/v1/repos/gitea_admin/local-repo"

# setup ArgoCD
echo
ARGOCD_HOST="argocd.${INGRESS_DOMAIN}"
cat <<EOF | helm upgrade --install argocd argo/argo-cd --wait --create-namespace --namespace=argocd --values=-
configs:
  cm:
    admin.enabled: false
    timeout.reconciliation: 10s
  params:
    server.insecure: true
    server.disable.auth: true
  repositories:
    local:
      name: local
      url: http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/local-repo.git
    remote:
      name: argocd-examples
      url: https://github.com/argoproj/argocd-example-apps.git
server:
  ingress:
    enabled: true
    ingressClassName: nginx
    hostname: "${ARGOCD_HOST}"
EOF

echo
cat <<EOF | kubectl apply -f -
---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-addons
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - git:
      repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/app-repo.git
      revision: HEAD
      directories:
      - path: apps/*
  template:
    metadata:
      name: '{{.path.basename}}'
    spec:
      project: "default"
      source:
        repoURL: http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/app-repo.git
        targetRevision: HEAD
        path: '{{.path.path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
          allowEmpty: true
        syncOptions:
        - CreateNamespace=true
        retry:
          limit: -1
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 10m
EOF

echo
echo "Checking out local-repo in repos/"
mkdir -p repos
git clone http://${GITEA_HOST}/gitea_admin/local-repo repos/local-repo
pushd repos/local-repo
git config user.name gitea_admin
git config user.email gitea_admin@localhost
git config credential.helper cache
git config credential.helper 'cache --timeout=3600'
popd

echo
echo "Gitea address: http://${GITEA_HOST}"
echo "Gitea login:"
echo "U: ${GITEA_USERNAME}"
echo "P: ${GITEA_PASSWORD}"
echo
echo "ArgoCD address: http://${ARGOCD_HOST}"
echo "More argocd examples: https://github.com/argoproj/argo-cd/tree/master/applicationset/examples/git-generator-directory"
echo 
