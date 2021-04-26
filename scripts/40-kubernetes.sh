#!/usr/bin/env bash

source /tmp/common.sh

retry apt-get update -o Acquire::ForceIPv4=true
retry apt-get install -y --no-install-recommends \
  openvpn \
  pkg-config


echo "installing Helm V3"
snap install helm --classic
