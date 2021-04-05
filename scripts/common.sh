#!/usr/bin/env bash

set -o errexit
set -o pipefail
shopt -s nullglob

if [ -f "/tmp/buildFailure" ]; then
  (>&2 echo "previous script $(cat "/tmp/buildFailure") has failed, ignore all subsequent scripts")
  exit 0
fi

trap 'catch $?' EXIT
catch() {
  if [ "$1" != "0" ]; then
    echo -n "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}" > "/tmp/buildFailure"
    exit 0
  fi
}

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