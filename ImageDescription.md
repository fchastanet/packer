# ReleaseNotes

## Description

Base image for running various development dev tools

### Image content

This image contains:

- docker/docker-compose
- git
- terminator/tmux
- vim
- Jetbrains toolbox
- chrome/firefox
- npm + prettier
- awscli + kubectl
- visual studio code
- php code tools : php_codesniffer, phpmd, php-cs-fixer, composer
- js code tools : prettier, sass-lint, stylelint, nodejs
- shell code tools: shellcheck

### Special features

Special features:

- apt daily updates disabled
- release upgrader disabled
- IPv6 enabled as chrome dev tools need it
- windows management : unity or lxde
- screen lock disabled
- keyboard fr automatically configured
- sleep mode disabled
- ntp disabled
- hibernate enabled
- inotify limit raised so phpstorm can be refreshed automatically when files are changing

### Desktop manager

${imageDesktopDesc}

## Releases

### V3.0.1

Release Date: 2021-04-06
Make X gnome or lxde startable with VMSVGA graphic controller
and 3D accelarated enabled
Raise root partition size to 100Go

### V3.0.0

Release Date: 2021-04-01
packer 1.7.1 migration
packer format changed to hcl (ubuntu.pkr.hcl)
packer minimal version from 1.6.5 to 1.7.1
virtual box minimal version from 6.1.16 to 6.1.18
vagrant minimal version from 2.2.14 to 2.2.15
aws minimal version from 2.1.1 to 2.1.33

### V2.1.2

Release Date: 2021-02-12
removed libreoffice to reduce imagesize
restored daily upgrade
upgraded docker-compose to 1.28.2
automatic upgrade during first vm launch
base image ubuntu live server 20.04.2

### V2.1.1

Release Date: 2021-02-01
removed unecessary screensaver

### V2.1

Release Date: 2020-11-29
first-start-local target build image using only one step image (00-ubuntu.json)
fixed lightdm initialization
Upgraded composer to latest version (V2.0.7 at writing time)
Upgraded nvm to v0.37.2

### V2.0.6

Release Date: 2020-11-24
Added aws-azure-login
Added some aws aliases
Enable zswap + create swapfile automatically
Added crontab to update vm time using ntp
Reverted to ubuntu 20.04.1 because impossible to launch X
ability to build only lxde or gnome desktop image and not both
packer minimal version from 1.6.0 to 1.6.5
virtual box minimal version 6.1.16 needed due to changes
  in kernel not compiling anymore vbox guest additions
upgraded number of cores from 2 to 4 in Vagrant config
Vagrantfile disable remote desktop

### V2.0.5

Release Date: 2020-10-04
Added ntp

### V2.0.4

Release Date: 2020-08-31
Removed hibernate + swapfile
Install Opengl/mesa drivers

### V2.0.3

Release Date: 2020-08-21
Upgraded to Ubuntu 20.10
installed recommended apt packages
Installation scripts are executable from any ubuntu image without packer

### V2.0.2

Release Date: 2020-08-17
Upgraded to Ubuntu 20.04.1
Adapted configuration to optimize ubuntu 20.04.1 performances
Added:
  lxde configuration

### V2.0.1

Release Date: 2020-07-31
upgraded docker-compose version to 1.26.2
root partition size raised from 20GB to 50GB
disable audio via vagrantfile
stabilize swap creation

### V2.0.0

Release Date: 2020-07-23
Migration to ubuntu 20.04
Added:

- multiple desktops configuration: gnome, lxde, server only
- awscli + kubectl
- visual studio code
- php code tools : php_codesniffer, phpmd, php-cs-fixer, composer
- js code tools : prettier, sass-lint, stylelint, nodejs
- shell code tools: shellcheck
- lxde default configuration
- awscli default configuration

### V1.0.5

Release Date: 2019-11-04
Added:

- added linters (sass-lint stylelint), formatters (prettier) and code sniffers (phpmd, php-cs-fixer, phpcbf)
- npm/composer usable by vagrant user (not root)

### V1.0.4

Release Date: 2019-10-10
Added:

- activate ipv6 as needed by google chrome dev tools

### V1.0.3

Release Date: 2019-09-09
Added:

- Visual studio code

### V1.0.2

Release Date: 2019-09-09
Changes:

- one image by desktop manager (gnome, lxde)

### V1.0.1

Release Date: 2019-09-05
Changes:

- replaced phpstorm install with jetbrains toolbox

### V1.0.0

Release Date: 2019-09-04
Base version

## FAQ

### Configure your keyboard if not fr

launch these commands:

```bash
dpkg-reconfigure keyboard-configuration
service keyboard-setup restart
```
