#!/usr/bin/env bash

source /tmp/common.sh

# ensure that we have insecure key to avoid vagrant 'Warning: Authentication failure. Retrying...'
# vagrant will renew this key automatically the first time once sucessfully connected
mkdir -pm 700 ${USERHOME}/.ssh
retry curl -L https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o ${USERHOME}/.ssh/authorized_keys
chmod 0600 ${USERHOME}/.ssh/authorized_keys
chown -R ${USERNAME}:${USERGROUP} ${USERHOME}/.ssh

# remove unwanted packages
apt-get -y remove ufw || true

# remove splash screen
sed -i \
  -e "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=''/" \
  -e "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX='quiet nosplash zswap.enabled=1 zswap.compressor=lz4'/" \
  /etc/default/grub

# Remove grub timeout
sed -i -e '/^GRUB_TIMEOUT=/aGRUB_RECORDFAIL_TIMEOUT=0' /etc/default/grub

update-grub

# SSH tweaks
echo "UseDNS no" >> /etc/ssh/sshd_config
