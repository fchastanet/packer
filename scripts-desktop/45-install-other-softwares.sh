#!/usr/bin/env bash

source /tmp/common.sh

# Update the box
retry apt-get -y update -o Acquire::ForceIPv4=true

# Install browsers
retry apt-get install -y -q --no-install-recommends \
  autojump \
  file-roller \
  gedit \
  terminator \
  tmux

# Install tmuxinator + tmuxinator dependencies
retry apt-get install -y -q --no-install-recommends \
    ruby
retry gem install tmuxinator
retry apt-get install -y -q --no-install-recommends \
  tmuxinator
