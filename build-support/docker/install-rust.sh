#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${RUST_VERSION}" ]
then
    error "Must set RUST_VERSION environment variable"
    exit 1
fi

if [ -z "${USERNAME}" ]
then
    error "Must set USERNAME environment variable"
    exit 1
fi

info "Install Rust dependencies"
apt install -y \
    build-essential \
    curl \
    git \
    libssl-dev \
    musl-tools \
    pkg-config

info "Installing Rustup and Rust components"
sudo -Hiu $USERNAME bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal --component clippy --component llvm-tools-preview --component rust-src --component rustfmt"
info "Installing specified Rust version: ${RUST_VERSION}"
sudo -Hiu $USERNAME bash -c "\$HOME/.cargo/bin/rustup install ${RUST_VERSION}"
for RUST_PLATFORM in \
    i686-pc-windows-gnu \
    x86_64-pc-windows-gnu \
    x86_64-unknown-linux-gnu \
    x86_64-unknown-linux-musl
do
    info "Installing sources for common platform: ${RUST_PLATFORM}"
    sudo -Hiu $USERNAME bash -c "\$HOME/.cargo/bin/rustup component add rust-std-${RUST_PLATFORM}"
done

info "Adding Rust tools to bash profile"
sudo -Hiu $USERNAME bash -c 'echo ". $HOME/.cargo/env" >> "$HOME/.bashrc"'
