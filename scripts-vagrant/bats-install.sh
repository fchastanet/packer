#!/usr/bin/env bash

# last version is not supported by gitbash
BATS_VERSION=v1.1.0
ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )

if [[ ! -f "${ROOT_DIR}/vendor/bats/bin/bats" ]]; then
    rm -Rf "${ROOT_DIR}/vendor/bats-install" "${ROOT_DIR}/vendor/bats"
    git clone https://github.com/bats-core/bats-core.git "${ROOT_DIR}/vendor/bats-install"
    cd "${ROOT_DIR}/vendor/bats-install" || exit 1
    git checkout ${BATS_VERSION}
    ./install.sh "${ROOT_DIR}/vendor/bats"
fi
