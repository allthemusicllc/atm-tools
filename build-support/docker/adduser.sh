#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${UID}" ]
then
    error "Must set the UID environment variable"
    exit 1
fi

if [ -z "${USERNAME}" ]
then
    error "Must set the USERNAME environment variable"
    exit 1
fi

apt install -y sudo

if ! ( getent passwd "${USERNAME}" )
then
    adduser \
        --home "/home/${USERNAME}" \
        --shell /bin/bash \
        --uid ${UID} \
        --disabled-password \
        ${USERNAME}
    passwd -d ${USERNAME}
    info "Added user ${USERNAME} with id ${UID}"

    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" && chmod 0440 "/etc/sudoers.d/${USERNAME}"
fi
