#!/usr/bin/env bash

set -o errexit
set -o pipefail
shopt -s nullglob
trap 'kill $(jobs -p)' TERM INT

set -x

PACKER_FILE="$1"
BOX_PACKED="$2"
LOG_FILE="$3"

echo "------------------------------------------------------------------------------------------"
echo "pack box ${PACKER_FILE}"
echo "------------------------------------------------------------------------------------------"
SECONDS=0
echo "Build started at $(date)" > logs/box-${BOX_VERSION}-${BOX_PACKED}-created

if [[ ! -f "iso/${UBUNTU_ISO_NAME}" ]]; then
  curl "${BASE_UBUNTU_ISO_URL}/${UBUNTU_ISO_NAME}" --output "iso/${UBUNTU_ISO_NAME}" || {
    (>&2 echo "Iso download has failed for url ${UBUNTU_ISO_URL}")
    exit 1
  }
fi

CURRENT_ISO_CHECKSUM="$((sha256sum "iso/${UBUNTU_ISO_NAME}" || true) | awk '{ print $1 }')"
if [ "${CURRENT_ISO_CHECKSUM}" != "${UBUNTU_ISO_CHECKSUM}" ]; then
  (>&2 echo "Iso checksum incorrect for file iso/${UBUNTU_ISO_NAME}")
  exit 1
fi

packer validate ${PACKER_FILE}
MSYS_NO_PATHCONV=1 PACKER_LOG=1 packer build \
    -var box_version="${BOX_VERSION}" \
    -var desktop="${BOX_PACKED}" \
    -var docker_compose_version="${DOCKER_COMPOSE_VERSION}" \
    -var headless="${HEADLESS}" \
    -var iso_url="${UBUNTU_ISO_URL}" \
    -var iso_checksum="${UBUNTU_ISO_CHECKSUM}" \
    -var nvm_version="${NVM_VERSION}" \
    -var ubuntu_version="${UBUNTU_VERSION}" \
    -var version="${BOX_VERSION}" \
    ${PACKER_FILE} 2>&1 | tee "${LOG_FILE}"

duration=$(eval "echo $(date -ud "@$SECONDS" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")
echo "Built at $(date)" >> logs/box-${BOX_VERSION}-${BOX_PACKED}-created
echo "Box ${BOX_PACKED} build has taken ${duration}" >> logs/box-${BOX_VERSION}-${BOX_PACKED}-created
