#!/usr/bin/env bats

BASE_USER=vagrant
CURRENT_DIR="$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )"
VBOX_SERVICE_VERSION="$(VBoxHeadless.exe --version | tail -1)"

execute_vagrant_ssh_command() {
    vagrant ssh -c "${*}" -- -n -T
}

@test "We can start the VM with vagrant" {
    vagrant up
}

@test "We can SSH inside the VM with vagrant" {
    sshOK=1
    while [[ "${sshOK}" = "1" || "${nbLoops}" -lt "20" ]]; do
      run vagrant ssh -c "echo OK" -- -n -T
      [[ "$status" -eq 0 ]] && {
        sshOK=0
        break
      }
      nbLoops=$((nbLoops+1))
      (>&3 echo "Loop ${nbLoops} wait 1s and retest to ssh to the VM")
      sleep 1
    done
    [[ "${sshOK}" = "0" ]]
}

@test "Default user of the VM is ${BASE_USER}" {
    execute_vagrant_ssh_command "whoami" | grep "${BASE_USER}"
}

@test "Default shell of default user ${BASE_USER} is bash" {
    # Configured User shell
    execute_vagrant_ssh_command 'echo ${SHELL}' | grep '/bin/bash'
    # Effective shell
    execute_vagrant_ssh_command 'echo ${0}' | grep 'bash'
}

@test "We have the passwordless sudoers rights inside the VM" {
    execute_vagrant_ssh_command 'sudo whoami' | grep root
}

@test "check file ${BATS_TEST_DIRNAME}/test_userData.vdi exists" {
    [[ -f "${BATS_TEST_DIRNAME}/test_userData.vdi" ]] || false
}

@test "The /home/vagrant filesystem is located on a LVM volume" {
     execute_vagrant_ssh_command 'sudo df -h /home/vagrant | grep "/dev/mapper/vps-vps" | wc -l'
}

@test "check vb-guest is installed" {
     execute_vagrant_ssh_command "which /usr/sbin/VBoxService && sudo /usr/sbin/VBoxService --version | grep \"${VBOX_SERVICE_VERSION}\""
}
