#!/usr/bin/env bash

source /tmp/common.sh

# Update the box
retry apt-get -y update --fix-missing -o Acquire::ForceIPv4=true

# install chrome prerequisites
retry apt-get install -y -q --no-install-recommends \
  gdebi-core \
  wget

retry wget -O /tmp/google-chrome-stable_current_amd64.deb \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
retry gdebi --non-interactive /tmp/google-chrome-stable_current_amd64.deb
rm -f /tmp/google-chrome-stable_current_amd64.deb

# Install browsers
retry apt-get install -y -q --no-install-recommends \
    firefox