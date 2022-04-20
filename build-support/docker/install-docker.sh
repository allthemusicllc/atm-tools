#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${DOCKER_GID}" ]
then
    error "Must set DOCKER_GID environment variable"
    exit 1
fi

if [ -z "${USERNAME}" ]
then
    error "Must set USERNAME environment variable"
    exit 1
fi

info "Setting timezone to UTC"
ln -s /usr/share/zoneinfo/UTC /etc/timezone
DEBIAN_FRONTEND=noninteractive \
    apt install -y tzdata

# See: https://docs.docker.com/engine/install/ubuntu/
info "Installing Docker dependencies"
DEBIAN_FRONTEND=noninteractive \
    apt install -y ca-certificates \
    curl \
    gnupg \
    lsb-release

info "Adding Docker GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

info "Adding Docker repository to APT sources"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

info "Installing Docker"
apt update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io

info "Creating group docker-host with GID ${DOCKER_GID}"
addgroup --gid "${DOCKER_GID}" docker-host
info "Adding user ${USERNAME} to docker-host group"
adduser "${USERNAME}" docker-host
