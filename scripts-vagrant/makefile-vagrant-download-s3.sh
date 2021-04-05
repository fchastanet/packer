#!/usr/bin/env bash
set -o errexit
set -o pipefail
shopt -s nullglob

USER="$1"
BOX_PATH="$2"
S3_BUCKET_URL="$3"
BOX_FILE="$(basename "${BOX_PATH}")"
BOX_NAME="${BOX_FILE%.*}"

if [ -z "${S3_BUCKET_URL}" ]; then
  (>&2 echo "please provide S3 bucket url")
  # ignore error so box could be downloaded via vagrant cloud
  exit 1
fi

if [ -z "${BOX_PATH}" ]; then
  (>&2 echo "please provide valid box file")
  exit 1
fi


if [ ! -f "${BOX_PATH}" ]; then
  # create base directory
  BASE_BOX_DIR="$(dirname "${BOX_PATH}")"
  if [ ! -d "${BASE_BOX_DIR}" ]; then
    mkdir -p "${BASE_BOX_DIR}" || {
      (>&2 echo "impossible to create directory for ${BOX_PATH}")
      exit 1
    }
  fi

  # download file from s3 bucket
  aws s3 cp "${S3_BUCKET_URL}/${BOX_FILE}" "${BOX_PATH}"
fi

# remove all the versioned boxes
vagrant box remove ${BOX_NAME} --all || true
# add the local box to registry
vagrant box add --force --name ${BOX_NAME} ${BOX_PATH}

# adapt box to Vagrantfile
sed -i \
  -e '/^[ \t]*virtualbox.vm.box_version = .*/d' \
  -e "s#VAGRANT_BOX = .*#VAGRANT_BOX = '${BOX_NAME}'#g" \
  -e "s#VM_NAME = .*#VM_NAME = '${BOX_NAME}'#g" Vagrantfile

