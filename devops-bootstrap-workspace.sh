#!/usr/bin/env bash

# This installs:
# - helm
# - kubectl
# - docker
# - kind

# Helm
if [ ! -f /usr/local/bin/helm ]
then
  echo "[INFO] installing helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Kubectl
if [ ! -f /usr/local/bin/kubectl ]
then
  echo "[INFO] installing kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
fi

# Docker
if [ ! -f /usr/bin/docker ]
then
  echo "[INFO] installing docker"
  curl https://get.docker.com | bash
  sudo chmod 666 /var/run/docker.sock
fi

# Kind
if [ ! -f /usr/local/bin/kind ]
then
  echo "[INFO] installing kind"
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
  sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
  rm -f kind
fi
