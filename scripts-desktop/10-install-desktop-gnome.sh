#!/usr/bin/env bash

source /tmp/common.sh
# this script will install default gnome desktop manager
if [[ "$DESKTOP" != "gnome" ]]; then
  exit 0
fi

echo "==> Checking version of Ubuntu"
cat /etc/lsb-release

echo "==> Installing ubuntu-desktop"
retry apt-get update -y --fix-missing -o Acquire::ForceIPv4=true
retry apt-get install -y -q --no-install-recommends \
    ubuntu-desktop

# default session to gnome
cat <<- EOF > /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
[Seat:*]
user-session=gnome
autologin-user=
autologin-user-timeout=0
# Check https://bugs.launchpad.net/lightdm/+bug/854261 before setting a timeout
greeter-session=lightdm-gtk-greeter
EOF
sed -i -e "s/autologin-user=/autologin-user=${USERNAME}/g" /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf