#!/usr/bin/env bash

source /tmp/common.sh

echo "install docker"
retry apt-get update -y --fix-missing -o Acquire::ForceIPv4=true
retry apt-get install -y -q --no-install-recommends \
    docker.io
groupadd docker || true
usermod -aG docker ${USERNAME} || true

echo "change docker files location"
service docker stop
mkdir ${USERHOME}/docker-files
mv /var/lib/docker/* ${USERHOME}/docker-files || true
rm -Rf /var/lib/docker || true
ln -s ${USERHOME}/docker-files /var/lib/docker
service docker start

echo "installing docker-compose ${DOCKER_COMPOSE_VERSION}"
retry curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
