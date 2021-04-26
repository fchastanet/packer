#!/usr/bin/env bash

set -x
set -o errexit

BOX_FILE="output-virtualbox-${DESKTOP}/${UBUNTU_VERSION}-${BOX_VERSION}-${DESKTOP}.box"
BOX=${BOX}-${DESKTOP}-${BOX_VERSION}

# remove all the versioned boxes
vagrant box remove -f ${BOX} --all || true
# add the local box to registry
vagrant box add --force --name ${BOX} ${BOX_FILE}

# adapt box to Vagrantfile
sed -i \
  -e '/^[ \t]*virtualbox.vm.box_version = .*/d' \
  -e "s#VAGRANT_BOX = .*#VAGRANT_BOX = '${BOX}'#g" \
  -e "s#VM_NAME = .*#VM_NAME = '${BOX}'#g" Vagrantfile

# up vagrant
vagrant up