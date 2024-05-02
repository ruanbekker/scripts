#!/usr/bin/env bash

# This installs:
# - helm
# - kubectl
# - docker
# - kind

# Vim extras
if [ "$EXTRAS_ENABLED" = "1" ]
then 
  # install vim configs
  curl https://raw.githubusercontent.com/ruanbekker/bash-setup/main/setup.sh | bash
  echo "[INFO] post-install: run :PlugInstall inside vim"
fi

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

# Kubectx
if [ ! -f /usr/local/bin/kubectx ]
then
  echo "[INFO] installing kubectx"
  jump_dir=$(mktemp -d)
  pushd $jump_dir
  wget https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubectx_v0.9.5_linux_x86_64.tar.gz
  tar -xf kubectx_v0.9.5_linux_x86_64.tar.gz
  sudo install -o root -g root -m 0755 kubectx /usr/local/bin/kubectx
  rm -f kubectx_v0.9.5_linux_x86_64.tar.gz
  popd
fi

# Kubens
if [ ! -f /usr/local/bin/kubens ]
then
  echo "[INFO] installing kubens"
  jump_dir=$(mktemp -d)
  pushd $jump_dir
  wget https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubens_v0.9.5_linux_x86_64.tar.gz
  tar -xf kubens_v0.9.5_linux_x86_64.tar.gz
  sudo install -o root -g root -m 0755 kubens /usr/local/bin/kubens
  rm -f kubens_v0.9.5_linux_x86_64.tar.gz
  popd
fi
  
# Stern
if [ ! -f /usr/local/bin/stern ]
then
  echo "[INFO] installing stern"
  jump_dir=$(mktemp -d)
  pushd $jump_dir
  wget https://github.com/stern/stern/releases/download/v1.26.0/stern_1.26.0_linux_amd64.tar.gz
  tar -xf stern_1.26.0_linux_amd64.tar.gz
  sudo install -o root -g root -m 0755 stern /usr/local/bin/stern
  rm -f stern_1.26.0_linux_amd64.tar.gz
  popd
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

# Btop
if [ ! -f /usr/local/bin/btop ] && [ "$EXTRAS_ENABLED" = "1" ]
then
  echo "[INFO] installing btop"
  pushd /tmp
  sudo apt install git wget gcc lbzip2 -y
  wget https://github.com/aristocratos/btop/releases/download/v1.2.13/btop-x86_64-linux-musl.tbz
  tar -xf btop-x86_64-linux-musl.tbz
  cd btop
  sudo make install
  popd
fi

# Populate config
# cat > kind-config.yaml << EOF
# kind: Cluster
# apiVersion: kind.x-k8s.io/v1alpha4
# nodes:
# - role: control-plane
# - role: worker
# - role: worker
# - role: worker
# EOF
# kind create cluster --config kind-config.yaml

# too many open files
# sudo sysctl -w fs.inotify.max_user_watches=2099999999
# sudo sysctl -w fs.inotify.max_user_instances=2099999999
# sudo sysctl -w fs.inotify.max_queued_events=2099999999
