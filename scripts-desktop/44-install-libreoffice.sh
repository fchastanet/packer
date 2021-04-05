#!/usr/bin/env bash

source /tmp/common.sh

add-apt-repository ppa:libreoffice/ppa
apt-get clean
retry apt-get -y update -o Acquire::ForceIPv4=true
retry apt-get install -y -q --no-install-recommends \
    libreoffice
