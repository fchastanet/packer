#!/usr/bin/env bash
set -o errexit
set -o pipefail
shopt -s nullglob

set -x
function retry {
  local n=1
  local max=5
  local delay=15
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        (>&2 echo "Command failed. Attempt $n/$max:")
        sleep $delay;
      else
        (>&2 echo "The command has failed after $n attempts.")
        return 1
      fi
    }
  done
  return 0
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

HOST_USERNAME="${HOST_USERNAME:-vagrant}"
USERNAME="${USERNAME:-vagrant}"
USERGROUP="${USERGROUP:-vagrant}"
USERHOME="${USERHOME:-/home/vagrant}"
VM_BOOTSTRAP_CONF_FILES="${VM_BOOTSTRAP_CONF_FILES:-/home/vagrantConf}"
VM_BOOTSTRAP_EXTERNAL_CONF_FILES="${VM_BOOTSTRAP_EXTERNAL_CONF_FILES:-/home/vagrantconfExternal}"
VAGRANT_PROVISIONING="${VAGRANT_PROVISIONING:-0}"

[[ "$(id -u)" = "0" ]] || {
    echo "bootstrap need to be executed as root - halt the vm"
    [[ "${VAGRANT_PROVISIONING}" = "1" ]] && sudo halt
    exit 1
}

err_report() {
    echo "Error on line $1"
    [[ "${VAGRANT_PROVISIONING}" = "1" ]] && halt
    exit 1
}
trap 'err_report $LINENO' ERR

REBOOT=0
# ensure we are in root home folder
cd /root

fixRights() {
    find ${USERHOME} -maxdepth 1 -type d -name ".*" \
        -exec chmod 755 {} ';' \
        -exec chown ${USERNAME}:${USERGROUP} {} ';'
    find ${USERHOME} -maxdepth 1 -type f -name ".*" \
        -exec chmod 640 {} ';' \
        -exec chown ${USERNAME}:${USERGROUP} {} ';'
}

# it could happen sometimes that sticky bit is lost on gosu executable
fixDockerGosu() {
    find ${USERHOME}/docker-files -name gosu -exec chown root:root {} ';'  -exec chmod +s {} ';'
}

moveHome() {
  # sdb is in the vps group
  # deactivate the logical volumes from vps group
  vgchange -d -a n vps
  # add sdb1 to fstab
  bash -c "echo '/dev/mapper/vps-vps ${USERHOME} ext4 defaults 0 2' >> /etc/fstab"
  bash -c 'date > /etc/provision_env_disk_added_date'

  # stop docker service during files copy
  service docker stop

  # first move ${USERHOME} that will be copied to the new disk
  (mkdir -p /tmp/homeMoved && shopt -s dotglob && mv ${USERHOME}/* /tmp/homeMoved && rm -Rf ${USERHOME})

  # reactivate the logical volumes from vps group
  vgchange -d -a y vps
  mkdir -vp ${USERHOME}
  mount ${USERHOME}

  # copy back the initial vagrant user files to this disk
  if [[ -f ${USERHOME}/.bashrc ]]; then
    echo "${USERHOME} is already initialized"
  else
    echo "initialize ${USERHOME} ..."
    (shopt -s dotglob && cp -r /tmp/homeMoved/* ${USERHOME})
    chown -R ${USERNAME}:${USERGROUP} ${USERHOME}
  fi
  rm -Rf /tmp/homeMoved

  fixRights
}

# if /dev/sdb1 is not in /etc/fstab then do the copy
if [[
  "${VAGRANT_PROVISIONING}" = "1" \
  && -L /dev/mapper/vps-vps && "$(cat /etc/fstab  | grep "${USERHOME} ")" = "" \
]]; then
  moveHome
  REBOOT=1
fi

# configure user settings at every startup
configure() {
    # configure vi/vim
    (
      shopt -s dotglob
      cp -r ${VM_BOOTSTRAP_CONF_FILES}/* ${USERHOME}
      [[ -d ${VM_BOOTSTRAP_EXTERNAL_CONF_FILES} ]] && cp -r ${VM_BOOTSTRAP_EXTERNAL_CONF_FILES}/* ${USERHOME}
      [[ -f ${USERHOME}/.externalConfPostInstall.sh ]] && chmod 755 ${USERHOME}/.externalConfPostInstall.sh
    )

    rm -R ${USERHOME}/etc
    fixRights

    dirs=(
      ${USERHOME}/.bin
      ${USERHOME}/.tmuxinator
    )

    for dir in "${dirs[@]}"; do
      echo "Fix rights of '${dir}'"
      chmod 755 "${dir}"
      chmod 755 "${dir}/*.sh" 2>/dev/null || true
    done
    chmod 755 ${USERHOME}/.bin/*

    # configure tmuxinator if needed
    if [[ ! -f ${USERHOME}/.bin/tmuxinator.bash ]]; then
      (
        mkdir -p ${USERHOME}/.bin
        retry curl https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash -o ${USERHOME}/.bin/tmuxinator.bash
        mkdir -p ${USERHOME}/.config/fish/completions
        retry curl https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.fish -o ${USERHOME}/.config/fish/completions/tmuxinator.fish
      )
    fi

    # Install ssh keys
    [[ -f ${USERHOME}/.ssh/authorized_keys ]] && cp ${USERHOME}/.ssh/authorized_keys ${USERHOME}/.ssh/authorized_keys_vagrant
    echo "=> copy host .ssh files to vagrant home"
    mkdir -pm 700 ${USERHOME}/.ssh
    if [[ -d /hostHome/.ssh ]]; then
      cp -R /hostHome/.ssh ${USERHOME}/
      find ${USERHOME}/.ssh -type f -exec chmod 600 {} ';'
      chown ${USERNAME}:${USERGROUP} ${USERHOME}/.ssh/*
      if [[ -f ${USERHOME}/.ssh/pub.key ]]; then
        mv ${USERHOME}/.ssh/pub.key ${USERHOME}/.ssh/id_rsa.pub
      fi
      chmod 644 ${USERHOME}/.ssh/id_rsa.pub || true
    fi

    if [[ -f ${USERHOME}/.ssh/authorized_keys_vagrant ]]; then
      cat ${USERHOME}/.ssh/authorized_keys_vagrant >> ${USERHOME}/.ssh/authorized_keys
      rm -f ${USERHOME}/.ssh/authorized_keys_vagrant
    fi

    # update .bashrc with dynamic variables
    if [[ -n "${HOST_USERNAME}" ]]; then
      sed -i -E \
        -e "s/export HOST_USERNAME=\"[^\"]*\"/export HOST_USERNAME=\"${HOST_USERNAME}\"/" \
        ${USERHOME}/.bash_profile_default
    fi

    [[ "${VAGRANT_PROVISIONING}" = "1" ]] && fixDockerGosu

    mkdir -p ${USERHOME}/.packer.doNotDelete || true
    # create file to avoid setting this part next time
    echo $(date) > ${USERHOME}/.packer.doNotDelete/v0
}
[[ ! -f ${USERHOME}/.packer.doNotDelete/v0 || ! -f ${USERHOME}/.gitignore ]] && configure

# configure user settings only when migrating from V0 to V1
configureV1() {
    # remove useless files
    rm -f ${USERHOME}/VBoxGuestAdditions.iso || true

    # configure dns
    if [[ -f "/etc/netplan/00-installer-config.yaml" ]]; then
      sed -i -e "s/addresses: \[8.8.8.8, 8.8.4.4\]$/addresses: [10.110.2.253, 8.8.4.4, 8.8.8.8]/" /etc/netplan/00-installer-config.yaml
      netplan generate && netplan apply
    fi

    # configure docker in order to use subnet different than 172.22.*.* (so zarmi does not work)
    cp ${VM_BOOTSTRAP_CONF_FILES}/etc/docker/daemon.json /etc/docker/daemon.json
    service docker restart

    # create file to avoid setting this part next time
    echo $(date) > ${USERHOME}/.packer.doNotDelete/v1
}
[[ ! -f ${USERHOME}/.packer.doNotDelete/v1 ]] && configureV1

# configure user settings only when migrating from V1 to V2
configureV2() {
    # install node latest version
    sudo -i -u ${USERNAME} bash -c "source /usr/local/nvm/nvm.sh && nvm install node"

    # install linters
    sudo -i -u ${USERNAME} bash -c "source /usr/local/nvm/nvm.sh && npm install -g prettier sass-lint stylelint"

    # create file to avoid setting this part next time
    echo $(date) > ${USERHOME}/.packer.doNotDelete/v2
}
[[ ! -f ${USERHOME}/.packer.doNotDelete/v2 ]] && configureV2

# configure user settings only when migrating from V3 to V4
configureV4() {
  REBOOT=1
  cp -r ${VM_BOOTSTRAP_CONF_FILES}/.config ${USERHOME}
  chown -R ${USERNAME}:${USERGROUP} \
    ${USERHOME}/.aws \
    ${USERHOME}/.bin \
    ${USERHOME}/.config \
    ${USERHOME}/.kube \
    ${USERHOME}/.local \
    ${USERHOME}/.tmuxinator

  cp ${VM_BOOTSTRAP_CONF_FILES}/etc/cron.hourly/* /etc/cron.hourly
  chmod 755 /etc/cron.hourly/*

  # create file to avoid setting this part next time
  echo $(date) > ${USERHOME}/.packer.doNotDelete/v4
}
[[ ! -f ${USERHOME}/.packer.doNotDelete/v4 ]] && configureV4

# upgrade system
retry apt-get update -y --fix-missing -o Acquire::ForceIPv4=true
retry apt-get upgrade -y
retry apt-get dist-upgrade -y

# execute external conf post install
[[ -f ${USERHOME}/.externalConfPostInstall.sh ]] && source ${USERHOME}/.externalConfPostInstall.sh

if [[ "${REBOOT}" = "1" ]]; then
    if [[ "${VAGRANT_PROVISIONING}" = "1" ]]; then
      # we need to reboot in order to restart docker and to let linux take home changes into account
      # to avoid issue "shell-init error retrieving current directory"
      /sbin/shutdown -r now < /dev/null > /dev/null 2>&1
    else
      echo 'please reboot in order to restart docker and to let linux take home changes into account'
      echo 'and to avoid issue "shell-init error retrieving current directory", please run'
      echo 'sudo reboot'
    fi
fi
