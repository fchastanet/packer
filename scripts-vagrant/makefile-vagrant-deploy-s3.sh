#!/usr/bin/env bash
set -o errexit
set -o pipefail
shopt -s nullglob

set -x

USER="$1"
BOX="$2"
S3_BUCKET_URL="$3"

if [ ! -f "${BOX}" ]; then
  (>&2 echo "box does not exists, please build it before")
  exit 1
fi

if [ -z "${S3_BUCKET_URL}" ]; then
  (>&2 echo "please provide S3 bucket url")
  exit 1
fi
aws s3 cp "${BOX}" "${S3_BUCKET_URL}"
