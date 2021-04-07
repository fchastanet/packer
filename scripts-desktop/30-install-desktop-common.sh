#!/usr/bin/env bash

source /tmp/common.sh

# x11 dependencies
retry apt-get upgrade -y
retry apt-get install -y -q --no-install-recommends \
  openbox \
  xorg

# this script will set common configuration for any desktop manager used
if [[ "$DESKTOP" = "serverX11" ]]; then
  exit 0
fi

USERNAME=${USERNAME:-vagrant}

echo "==> install drivers for SVGA"
# @see https://blogs.oracle.com/scoter/oracle-vm-virtualbox-61-3d-acceleration-for-ubuntu-1804-and-2004-virtual-machines
# Install  required packages for building kernel modules.
retry apt-get install -y -q --no-install-recommends \
  build-essential \
  dkms \
  gnome-keyring \
  module-assistant \
  nux-tools \
  xserver-xorg-video-vmware-hwe-18.04

# Prepare your system to build kernel module
m-a prepare

echo "==> common desktop configuration"

echo "==> create /usr/local/bin/desktop-custom-configure file"
cat <<- EOF > /usr/local/bin/desktop-custom-configure
#!/bin/bash

# xset -dpms s off s noblank s 0 0 s noexpose
# disable screen saver
xset s off &

# prevent the display from blanking
xset s noblank &

# prevent the monitor's DPMS energy saver from kicking in
xset -dpms &

# disable lock screen
gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true' &
gsettings set org.gnome.desktop.screensaver lock-enabled false &

# disable screen blackout. This stops the shield but means the monitor remains permanently on (fixed by DPMS below)
gsettings set org.gnome.desktop.session idle-delay 0 &

# Disable gnome power plugin (this plugin will always disable the DPMS timeouts you set below)
gsettings set org.gnome.settings-daemon.plugins.power active false &

# enable num lock
gsettings set org.gnome.settings-daemon.peripherals.keyboard numlock-state 'on'

# disable automatic suspend
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
EOF
mkdir -p /usr/local/bin
chmod 755 /usr/local/bin/desktop-custom-configure

LIGHTDM_CONFIG=/etc/lightdm/lightdm.conf.d/20-lubuntu.conf
GDM_CUSTOM_CONFIG=/etc/gdm3/custom.conf

if [ -f $GDM_CUSTOM_CONFIG ]; then
    mkdir -p $(dirname ${GDM_CUSTOM_CONFIG})
    echo "" > $GDM_CUSTOM_CONFIG
    echo "[daemon]" >> $GDM_CUSTOM_CONFIG
    echo "# Enabling automatic login" >> $GDM_CUSTOM_CONFIG
    echo "AutomaticLoginEnable = true" >> $GDM_CUSTOM_CONFIG
    echo "AutomaticLogin = ${USERNAME}" >> $GDM_CUSTOM_CONFIG
fi

if [ -d /etc/lightdm/lightdm.conf.d ]; then
    echo "==> Configuring lightdm autologin"
    echo "[SeatDefaults]" >> $LIGHTDM_CONFIG
    echo "autologin-user=${USERNAME}" >> $LIGHTDM_CONFIG
    echo "autologin-user-timeout=0" >> $LIGHTDM_CONFIG
    echo "allow-guest=true" >> $LIGHTDM_CONFIG
fi

if [ -d /etc/xdg/autostart/ ]; then
    echo "==> Custom xdg config (no screen blank, ...)"

    NODPMS_CONFIG=/etc/xdg/autostart/customXdgConfig.desktop
    echo "[Desktop Entry]" >> $NODPMS_CONFIG
    echo "Type=Application" >> $NODPMS_CONFIG
    echo "Exec=/usr/local/bin/desktop-custom-configure" >> $NODPMS_CONFIG
    echo "Hidden=false" >> $NODPMS_CONFIG
    echo "NoDisplay=false" >> $NODPMS_CONFIG
    echo "X-GNOME-Autostart-enabled=true" >> $NODPMS_CONFIG
    echo "Name[en_US]=custom xdg configuration" >> $NODPMS_CONFIG
    echo "Name=nodpms" >> $NODPMS_CONFIG
    echo "Comment[en_US]=" >> $NODPMS_CONFIG
    echo "Comment=" >> $NODPMS_CONFIG
fi

retry apt-get install -y -q --no-install-recommends \
  appmenu-gtk2-module \
  appmenu-gtk3-module \
  `# a package which contains Cleanlooks, Motif, Plastique, and Gtk+ 2 Qt5 styles` \
  qt5-style-plugins \
  ttf-ubuntu-font-family