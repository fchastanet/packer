#!/usr/bin/env bash

CURRENT_DIR=$( cd "$( readlink -e "${BASH_SOURCE[0]%/*}" )" && pwd )

# shellcheck source=conf/.bin/Utils.sh
source "$(cd "${CURRENT_DIR}/../conf/.bin" && pwd)/Utils.sh"

PACKER_MINIMAL_VERSION="1.7.1"
VAGRANT_MINIMAL_VERSION="2.2.15"
VIRTUALBOX_MINIMAL_VERSION="6.1.18"
AWS_MINIMAL_VERSION="2.1.33"

Version::checkMinimal "packer" "packer version" "${PACKER_MINIMAL_VERSION}" || {
  [[ "$1" = "packer-mandatory" ]] && exit 1
  Log::displayWarning "OK - packer is not needed in this case"
}
Version::checkMinimal "vagrant" "vagrant -v" "${VAGRANT_MINIMAL_VERSION}" || exit 1
Version::checkMinimal "vboxmanage" "vboxmanage --version" "${VIRTUALBOX_MINIMAL_VERSION}" || exit 1
if [[ -n "${S3_BUCKET_URL}" ]]; then
  Version::checkMinimal "aws" "aws --version | sed -E 's#aws-cli/([^ ]+).*#\1#g'" "${AWS_MINIMAL_VERSION}" || exit 1
fi

if [ "$(Functions::isWindows; echo $?)" = "1" ]; then
  # on windows, sometimes packer executable doesn't terminate
  # check if packer already running
  if ps aux | grep packer; then
    Log::displayError "packer is already running, terminate these processes before"
    exit 1
  fi
fi