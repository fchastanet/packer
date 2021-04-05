#!/usr/bin/env bash

source /tmp/common.sh

# this script will install https://lxde.net/ desktop manager
if [[ "$DESKTOP" != "lxde" ]]; then
  exit 0
fi

echo "==> Checking version of Ubuntu"
cat /etc/lsb-release

echo "==> Installing lxde"
add-apt-repository universe -y
add-apt-repository multiverse -y
retry apt-get update -y --fix-missing -o Acquire::ForceIPv4=true
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
retry apt-get install -y -q --no-install-recommends \
    libcanberra-gtk-module
retry apt-get install -y -q --no-install-recommends \
    libcanberra-gtk3-module
retry apt-get install -y -q --no-install-recommends \
    lightdm
retry apt-get install -y -q --no-install-recommends \
    lightdm-gtk-greeter
retry apt-get install -y -q --no-install-recommends \
    lubuntu-default-settings
retry apt-get install -y -q --no-install-recommends \
    lxappearance
retry apt-get install -y -q --no-install-recommends \
    lxterminal
retry apt-get install -y -q --no-install-recommends \
    x11-xkb-utils

echo "==> Installing lxpanel (taskbar)"
retry apt-get install -y -q --no-install-recommends \
    lxpanel

echo "==> Installing lxsession (auto start application)"
retry apt-get install -y -q --no-install-recommends \
    lxsession

echo "==> Installing openbox - see https://doc.ubuntu-fr.org/openbox"
retry apt-get install -y -q --no-install-recommends \
    obconf \
    openbox \
    openbox-lxde-session

# keep sure that lightdm is selected and not gdm3
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true dpkg-reconfigure lightdm
echo "set shared/default-x-display-manager lightdm" | debconf-communicate

# default session to lxde
# Check https://bugs.launchpad.net/lightdm/+bug/854261 before setting a timeout
cat <<- EOF > /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
[Seat:*]
user-session=LXDE
greeter-setup-script=/usr/bin/numlockx on
autologin-user=
autologin-user-timeout=0
greeter-session=lightdm-gtk-greeter
EOF
sed -i -e "s/autologin-user=/autologin-user=${USERNAME}/g" /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
