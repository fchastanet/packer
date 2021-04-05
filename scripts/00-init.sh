#!/usr/bin/env bash

source /tmp/common.sh

# change root password
echo "root:root"| chpasswd

# Set up vagrant sudo
echo "${USERNAME} ALL=NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

# APT If this is non-zero APT will retry failed files the given number of times.
echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

# We need to resize the logical volume to use all the existing and free space of the volume group
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

# And then, we need to resize the file system to use the new available space in the logical volume
resize2fs /dev/ubuntu-vg/ubuntu-lv
