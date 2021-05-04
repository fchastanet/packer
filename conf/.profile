#!/bin/bash

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.bin" ] ; then
    PATH="$HOME/.bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Paths
if [[ -d "${HOME}/projects/bash-tools/bin" ]]; then
    export PATH="${HOME}/projects/bash-tools/bin:${PATH}"
fi

#kubectx and kubens
export PATH=/opt/kubectx:$PATH

export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm


# Set Qt5 applications to use the Gtk+ 2 style
export QT_QPA_PLATFORMTHEME=gtk2

# used by docker-sync
export DOCKER_HOST="unix:///var/run/docker.sock"

export EDITOR='vim'

export LC_TIME=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export IBUS_ENABLE_SYNC_MODE=1

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi