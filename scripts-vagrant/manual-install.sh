#!/usr/bin/env bash

set -o errexit
set -o pipefail

export DEBIAN_FRONTEND=noninteractive
export DESKTOP="${DESKTOP:-gnome}"
export USERHOME="${USERHOME:-/home/vagrant}"
export USERNAME="${USERNAME:-vagrant}"
export USERGROUP="${USERGROUP:-vagrant}"

for script in "$@"
do
    echo "Execute ${script}"
    sudo -E -S bash "${script}"
done

# TODO make tests => test this install