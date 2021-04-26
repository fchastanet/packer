#!/usr/bin/env bash

source /tmp/common.sh

# this script will set common configuration


echo "==> common configuration"
echo "DESKTOP=${DESKTOP}"
echo "BOX_VERSION=${BOX_VERSION}"
echo "USERNAME=${USERNAME}"
echo "USERGROUP=${USERGROUP}"

echo "==> ensure we have last ubuntu version"
retry apt-get -y update -o Acquire::ForceIPv4=true
echo "==> dist upgrade to last version (not lts)"
retry apt-get install -y -q ubuntu-release-upgrader-core
sed -i -e 's/^Prompt=.*$/Prompt=normal/' /etc/update-manager/release-upgrades
do-release-upgrade || true

echo "==> configure fr keyboard"
L='fr' && sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'$L'\"/g' /etc/default/keyboard

# sync datetime auto
retry apt-get install -y -q ntp ntpdate
#  disable Ubuntu's default timesyncd service, as this conflicts with ntp
timedatectl set-ntp off || true

# disable sleep mode
echo "==> disable sleep mode"
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target

# disable sound service
apt-get remove -y --purge pulseaudio
apt-get autoremove -y

# raise inotify limit
if [[ ! -f /etc/sysctl.d/99-idea.conf ]]; then
    echo "=> raise inotify limit"
    echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/99-idea.conf
    sysctl -p --system
fi

# add the user to a group autologin
groupadd -r autologin
gpasswd -a ${USERNAME} autologin

# remove screensaver
apt-get remove -y --purge xscreensaver
apt-get autoremove -y