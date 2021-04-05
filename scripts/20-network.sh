#!/usr/bin/env bash

source /tmp/common.sh

# Adding a 2 sec delay to the interface up, to make the dhclient happy
echo "pre-up sleep 2" >> /etc/network/interfaces

# Disable DNS reverse lookup
echo "UseDNS no" >> /etc/ssh/sshd_config

# add dns
echo "dns-nameservers 10.110.2.253,8.8.8.8 8.8.4.4" >> /etc/network/interfaces
