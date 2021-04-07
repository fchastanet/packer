#!/usr/bin/env bash

source /tmp/common.sh

# Update the box
retry apt -y update -o Acquire::ForceIPv4=true

# configure language support
retry apt install -y -q --no-install-recommends \
    tzdata \
    $(check-language-support)

# Install dependencies
retry apt install -y -q --no-install-recommends \
    build-essential \
    curl \
    dos2unix \
    git \
    libappindicator1 \
    libindicator7 \
    libxss1 \
    mlocate \
    mysql-client \
    nfs-common \
    nfs-kernel-server \
    openssl \
    parallel \
    putty-tools \
    pv \
    unzip \
    vim \
    vim-gui-common \
    vim-runtime \
    wget