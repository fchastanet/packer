#!/usr/bin/env bash
BOX_TESTED="$1"
VAGRANTFILE_TEMPLATE="$2"
BATS_FILE="$3"
BOX_VERSION="$4"

trap 'kill $(jobs -p)' TERM INT

CURRENT_DIR="$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )"
ROOTDIR="$( cd "${CURRENT_DIR}/.." && pwd )"
SECONDS=0

BOX_FILE="${ROOTDIR}/${BOX_FILE_PREFIX}-${BOX_TESTED}/${UBUNTU_VERSION}-${BOX_VERSION}-${BOX_TESTED}.box"
BOX_NAME="packer-test"

# skip test if vm box does not exist
if [[ ! -f "${BOX_FILE}" ]]; then
  (>&2 echo "vm ${BOX_TESTED} tests skipped as vm image not built")
  exit 0
fi

# register-box:
vagrant box add --force --name "${BOX_NAME}" "${BOX_FILE}" || {
  (>&2 echo "unable to add the box from ${BOX_FILE}")
  exit 1
}

function cleanBox {
    # clean box
    (
        cd "${ROOTDIR}/tests"
        vagrant destroy -f || true
        rm -rf Vagrantfile .vagrant || true
        vagrant box remove "${BOX_NAME}" || true
        rm -f "test_userData.vdi" || true
        vagrant global-status --prune
    )
}
trap cleanBox EXIT ABRT QUIT INT TERM

# execute tests
(
    cd ${ROOTDIR}/tests
    rm -f Vagrantfile
    cp "${VAGRANTFILE_TEMPLATE}" Vagrantfile
    sed -i \
        -e "s#@@@VAGRANT_BOX@@@#${BOX_NAME}#g" \
        -e "s#@@@BOX_TESTED@@@#${BOX_TESTED}#g" \
        Vagrantfile
    "${ROOTDIR}/vendor/bats/bin/bats" "./${BATS_FILE}" 2>&1 | tee -a "${ROOTDIR}/logs/box-${BOX_VERSION}-${BOX_TESTED}-tests.log"
    exitCode=$PIPESTATUS

    duration=$(eval "echo $(date -ud "@$SECONDS" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")
    boxCreatedLogFilePath="${ROOTDIR}/logs/box-${BOX_VERSION}-${BOX_TESTED}-created"
    if [[ "${exitCode}" = "0" ]]; then
        echo "Box ${BOX_PACKED} Tests ${BATS_FILE} OK on $(date) (duration: ${duration})" >> "${boxCreatedLogFilePath}"
    else
      echo "Box ${BOX_PACKED} Tests ${BATS_FILE} FAILURE on $(date) (duration: ${duration})" >> "${boxCreatedLogFilePath}"
      echo "Box ${BOX_PACKED} Tests ${BATS_FILE} check test logs : ${ROOTDIR}/logs/box-${BOX_TESTED}-tests.logs" >> "${boxCreatedLogFilePath}"
    fi
)
