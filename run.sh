#!/usr/bin/env bash

set -eu

###################
##### Imports #####
###################

# Check if running in build container or locally
# to import from correct path
if [ -d /build-support ]
then
    . ~/.bashrc
    . ~/.cargo/env
    BUILD_SUPPORT_ROOT="/build-support"
else
    BUILD_SUPPORT_ROOT="./build-support"
fi
. "${BUILD_SUPPORT_ROOT}/shell/run/config.sh"
. "${BUILD_SUPPORT_ROOT}/shell/common/log.sh"


###############################
##### Container Utilities #####
###############################

run-build-base() {
    ${CONTAINER_RUNTIME} build \
        --target "${BUILD_TARGET_STAGE}" \
        -t "${BUILD_IMAGE_URL}:${BUILD_IMAGE_TAG}" \
        -f build-support/docker/Dockerfile \
        --build-arg DOCKER_GID="${DOCKER_GID}" \
        --build-arg RUST_VERSION="${DEFAULT_RUST_VERSION}" \
        --build-arg UID="${USERID}" \
        --build-arg USERNAME="${USERNAME}" \
        "${@}" \
        .
}

run-push-base() {
    ${CONTAINER_RUNTIME} push \
        "${@}" \
        "${BUILD_IMAGE_URL}:${BUILD_IMAGE_TAG}"
}

run-in-container() {
    # If input device is not a TTY don't run with `-it` flags
    local INTERACTIVE_FLAGS="$(test -t 0 && echo '-it' || echo '')"
    ${CONTAINER_RUNTIME} run \
		--rm \
         ${INTERACTIVE_FLAGS} \
		-u ${USERNAME} \
        -v /var/run/docker.sock:/var/run/docker.sock \
		-v $(pwd):/project \
		-w /project \
		${BUILD_IMAGE_URL}:${BUILD_IMAGE_TAG} \
        --local "${@}"
}


#############################
##### Command Utilities #####
#############################

run-command() {
    local COMMAND="${1}"
    shift

    if [ ${RUNTIME_CONTEXT} = "container" ]
    then
        run-in-container "${COMMAND}" "${@}"
    elif [ ${RUNTIME_CONTEXT} = "local" ]
    then
        run-${COMMAND} "${@}"
    else
        error "Invalid value for RUNTIME_CONTEXT: ${RUNTIME_CONTEXT}"
        exit 1
    fi
}


####################
##### Commands #####
####################

run-build() {
    run-check

    run-fmt-check

    run-lint

    run-check-deps

    run-test "${@}"

    info "Compiling package"
    cross build "${@}"
}

run-check() {
    info "Checking package for errors"
    cross check "${@}"
}

run-check-deps() {
    info "Checking dependencies for license compliance"
    cargo deny check licenses "${@}"

    info "Checking dependencies for security notices"
    cargo deny check advisories "${@}"

    info "Checking dependencies for trusted and banned sources"
    cargo deny check bans "${@}" && \
        cargo deny check sources "${@}"
}

run-clean() {
    info "Removing Cargo build artifacts"
    cargo clean "${@}"
}

run-exec() {
    info "Running command: ${@}"
    ${@}
}

run-fmt() {
    info "Formatting code with Rustfmt"
    cargo fmt "${@}"
}

run-fmt-check() {
    info "Checking code format with Rustfmt"
    cargo fmt "${@}" -- --check
}

run-init() {
    if ! [ -z "$(ls src/)" ]
    then
        error "Project already initialized, aborting"
        exit 1
    fi

    read -e -p "Do you want to include .gitconfig in this project's Git config [y/n]? " INCLUDE_GITCONFIG
    if ( [ "${INCLUDE_GITCONFIG,,}" = "y" ] && [ -d "./git/" ] )
    then
        git config --local include.path ../.gitconfig
    fi

    local DEFAULT_PACKAGE_NAME="$(basename $(pwd))"
    local DEFAULT_PACKAGE_TARGET="lib"
    
    read -e -p "Package name [${DEFAULT_PACKAGE_NAME}]: " PACKAGE_NAME
    PACKAGE_NAME="${PACKAGE_NAME:-${DEFAULT_PACKAGE_NAME}}"
    local PACKAGE_DIRECTORY="${PACKAGE_NAME/_/-}"
    read -e -p "Package target (bin or lib) [${DEFAULT_PACKAGE_TARGET}]: " PACKAGE_TARGET
    PACKAGE_TARGET="${PACKAGE_TARGET:-${DEFAULT_PACKAGE_TARGET}}"
    PACKAGE_TARGET="${PACKAGE_TARGET,,}"
    if ! ( [ "${PACKAGE_TARGET}" = "bin" ] || [ "${PACKAGE_TARGET}" = "lib" ] )
    then
        warn "Invalid package target '${PACKAGE_TARGET}', defaulting to ${DEFAULT_PACKAGE_TARGET}"
        PACKAGE_TARGET="${DEFAULT_PACKAGE_TARGET}"
    fi

    PACKAGE_TARGET="${PACKAGE_TARGET:-}"
    cargo new --name "${PACKAGE_NAME}" --vcs none --${PACKAGE_TARGET} "src/${PACKAGE_DIRECTORY}"

    # Update index document for documentation to point to package
    sed -i'' \
        -e "s/template_repo_rs/${PACKAGE_NAME}/g" \
        docs/index.html
}

run-lint() {
    info "Linting code with Clippy"
    cargo clippy "${@}"
}

run-make-docs() {
    info "Compiling package documentation"
    local DOC_BUILD_DIR=$(mktemp -d)
    cargo doc --no-deps --target-dir "${DOC_BUILD_DIR}" "${@}"
    mv ${DOC_BUILD_DIR}/doc/* docs/
    rm -rf "${DOC_BUILD_DIR}"
}

run-publish() {
    info "Creating and publishing distribution packages to crates.io"
    cargo publish "${@}"
}

run-shell() {
    info "Entering shell"
    bash
}

run-test() {
    # See https://github.com/mozilla/grcov#example-how-to-generate-gcda-files-for-a-rust-project
    # for documentation on generating .gcda file for a Rust project
    info "Compiling package with coverage information"
    export CARGO_INCREMENTAL=0
    export RUSTC_BOOTSTRAP=1
    export RUSTDOCFLAGS="-Cpanic=abort"
    export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort"
    cross build "${@}"
    
    info "Running package tests"
    cross test "${@}"

    info "Generating coverage report with grcov"
    TARGET_PLATFORM="$(echo ${@} | grep -o '\-\-target [^ ]\+' | sed 's/--target//g' | tr -d '[:space:]')"
    if [ -z "${TARGET_PLATFORM}" ]
    then
        TARGET_ROOT_DIRECTORY="./target/debug"
    else
        TARGET_ROOT_DIRECTORY="./target/${TARGET_PLATFORM}"
    fi
    grcov . -s . --binary-path "${TARGET_ROOT_DIRECTORY}/" -t html --branch --ignore-not-existing -o "${TARGET_ROOT_DIRECTORY}/coverage/"
}

run-update-deps() {
    info "Updating dependencies"
    cargo update "${@}"
}


################
##### Main #####
################

print-usage() {
    echo "usage: $(basename ${0}) [-h] [SUBCOMMAND]"
    echo
    echo "subcommands:"
    echo "build             cross-build: compile package (default subcommand)"
    echo "build-base        build the build container image"
    echo "check             cross-check: check package for errors"
    echo "check-deps        cargo-deny: check dependencies for license compliance, security notices, and trusted sources"
    echo "clean             cargo-clean: remove Cargo build artifacts"
    echo "exec              execute arbitrary shell commands"
    echo "fmt               format code with Rustfmt"
    echo "init              initialize repository (should only be run once)"
    echo "lint              lint code with Clippy"
    echo "make-docs         cargo-doc: compile package documentation"
    echo "publish           publish package to crates.io"
    echo "push-base         push build container image to registry"
    echo "shell             start Bash shell"
    echo "test              cross-test: run unit, documentation, and integration tests and code coverage"
    echo "update-deps       cargo-update: update dependencies in Cargo.lock file"
    echo
    echo "optional arguments:"
    echo "-h, --help        show this help message and exit"
    echo "-l, --local       run command on host system instead of build container"
    echo "-c, --container   run command in build container"
    echo
}


while :
do
    case "${1:-}" in
        -c|--container)
            shift
            RUNTIME_CONTEXT="container"
        ;;
        -h|--help)
            print-usage
            exit 0
        ;;
        -l|--local)
            shift
            RUNTIME_CONTEXT="local"
        ;;
        *)
            break
        ;;
    esac
done

if [ -z "${1:-}" ]
then
    COMMAND="${DEFAULT_COMMAND}"
else
    COMMAND="${1}"
    shift
fi

# These commands should explicitly run locally
if ( \
    [ "${COMMAND}" = "build-base" ] \
    || [ "${COMMAND}" = "push-base" ] \
)
then
    RUNTIME_CONTEXT="local"
fi

run-command "${COMMAND}" "${@}"
