#!/usr/bin/env bash

# Clean up
echo "==> Clean up"
apt-get -y autoremove --purge
apt-get -y clean

# Remove temporary files
rm -rf /tmp/*

# writes zeroes to all empty space on the volume; this allows for better compression of the physical file containing the virtual disk.
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY
