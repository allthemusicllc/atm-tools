#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${USERNAME}" ]
then
    error "Must set USERNAME environment variable"
    exit 1
fi

info "Installing Cross for cross-compilation and testing"
sudo -Hiu $USERNAME bash -c '$HOME/.cargo/bin/cargo install --locked cross'

info "Installing cargo-deny for dependency linting"
sudo -Hiu $USERNAME bash -c '$HOME/.cargo/bin/cargo install --locked cargo-deny'

info "Installing grcov for rendering coverage reports"
sudo -Hiu $USERNAME bash -c '$HOME/.cargo/bin/cargo install --locked grcov'
