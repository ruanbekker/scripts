#!/bin/bash

os="darwin"
arch="amd64"
version="1.6.1"

if [ ! -f "loki-local-config.yaml" ]
  then wget https://raw.githubusercontent.com/grafana/loki/v${version}/cmd/loki/loki-local-config.yaml
fi

if [ ! -f "loki-${os}-${arch}" ]
  then
       wget https://github.com/grafana/loki/releases/download/v${version}/loki-${os}-${arch}.zip
       unzip loki-${os}-${arch}.zip
fi
./loki-${os}-${arch} -config.file=loki-local-config.yaml
