#!/usr/bin/env bash

source /tmp/common.sh

retry apt-get update -y -o Acquire::ForceIPv4=true
retry apt-get dist-upgrade -y

# next script will have to wait before starting
if [[ "${REBOOT}" = "1" ]]; then
  /sbin/shutdown -r now < /dev/null > /dev/null 2>&1
  exit 0
fi