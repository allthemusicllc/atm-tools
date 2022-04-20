# Developer Workflow

## Overview

This repository uses custom tooling based on shell (Bash) scripts and Docker to unify local and CI/CD workflows.
The idea is that by running the developer workflow in a container, when those commands are run on CI/CD servers they will be executed in the exact same environment.
While this does create an explicit dependency on a container runtime like Docker or Podman,
it reduces the variance between local and remote environments and thus reduces the likelihood of "well, it works on my machine."
Unifying local and remote workflows is not a novel concept, but the build system in this repo is custom-built.
This document describes in detail how to use and customize it. To skip the explanation and get started immediately, skip straight to [Initializing the Repo](#initializing-the-repo).

## Requirements

The build system currently only supports Linux (native or WSL) and macOS, and requires [Docker](https://www.docker.com/) or another container runtime with a similar CLI.
If you're using an editor like Vim/Neovim and want code completion and IDE-like features, you may also need a local Rust installation (consult your code completion plugin's documentation).
That's it! All other development dependencies are installed in the build container.

## Build Container

The build container, defined in [build-support/docker/Dockerfile](build-support/docker/Dockerfile), is based on [Ubuntu 20.04 LTS (focal)](https://hub.docker.com/_/ubuntu).
It includes a `minimal` installation of [Rustup and Rust](https://www.rust-lang.org/tools/install),
as well as [Cross](https://github.com/cross-rs/cross) for cross-compilation,
[cargo-deny](https://docs.rs/cargo-deny/latest/cargo_deny/) for dependency linting,
and [grcov](https://github.com/mozilla/grcov) for coverage report generation.
The repository files are mounted into the container before each command is run, so the container is not rebuilt after any source files are changed.
To add tools or make other changes to the build container, edit the `build` or any preceding stage in the [Dockerfile](build-support/docker/Dockerfile)
and rebuild it.

## Build CLI

All development commands are run via the [run.sh](run.sh) script, which comes with many common commands built-in for Rust development (detailed below).
Certain build settings are configurable via [config.sh](build-support/shell/run/config.sh), and each setting is documented in that file.
If you are not using Docker (and are using local development instead), make sure to update the `CONTAINER_RUNTIME` setting in `config.sh` before continuing.

### Initializing the Repo

Once you have installed a container runtime and it's working properly, clear the workspace and build the build container:

```bash
./run.sh -l clean && ./run.sh build-base
```

Initialize the project with a project name and description, module name, author, and source code license:

```bash
./run.sh init
```

Now you're ready to start hacking!

### The Inner Loop 

The common set of steps you might want to perform while writing code are formatting, type checking, linting, testing, building, and publishing.
The default command, `build`, checks the format and types, lints the code and dependencies, runs unit tests, and compiles the package(s):

```bash
./run.sh # equivalent to ./run.sh build
```

This command should be run before comitting any code to the repo, and can be used in precommit hooks or CI/CD scripts.
To format code before checking, run the `fmt` command before `build`:

```bash
./run.sh fmt \
    && ./run.sh build
```

Once you're ready to _publish_ your code to [crates.io](https://crates.io/) or another registry, and compile the documentation, run:

```bash
./run.sh publish \
    && ./run.sh make-docs
```

### Build CLI Commands

The table below contains all the built-in commands, their usage, and a brief description.

| Command     | Usage                        | Description                                                                                                                                                                                                  |
|-------------|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| build       | `./run.sh build`             | Build distribution packages. Before building, this command will check the code format, run the type checker and linter, lint dependencies, and run unit and integration tests. This is the default command.  |
| build-base  | `./run.sh build-base`        | Build the build container image.                                                                                                                                                                             |
| check       | `./run.sh check`             | Check package for errors with [cargo-check](https://doc.rust-lang.org/cargo/commands/cargo-check.html).                                                                                                      |
| check-deps  | `./run.sh check-deps`        | Check dependencies for license compliance, security notices, and trusted sources with [cargo-deny](https://docs.rs/cargo-deny/latest/cargo_deny/).                                                           |
| clean       | `./run.sh clean`             | Clean the workspace by removing Cargo build artifacts with [cargo-clean](https://doc.rust-lang.org/cargo/commands/cargo-clean.html).                                                                         |
| exec        | `./run.sh exec COMMAND`      | Execute arbitrary shell command (`COMMAND`).                                                                                                                                                                 |
| fmt         | `./run.sh fmt`               | Format code with [Rustfmt](https://github.com/rust-lang/rustfmt).                                                                                                                                            |
| init        | `./run.sh init`              | Initialize repository with project name and description, module name, author, and source code license (should only be run once - see [Initializing the Repo](#initializing-the-repo)).                       |
| lint        | `./run.sh lint`              | Lint code with [Clippy](https://github.com/rust-lang/rust-clippy).                                                                                                                                           |
| make-docs   | `./run.sh make-docs`         | Compile package documentation with [carg-doc](https://doc.rust-lang.org/cargo/commands/cargo-doc.html).                                                                                                      |
| publish     | `./run.sh publish`           | Publish package to [crates.io](https://crates.io/) (or another registry) using [cargo-publish](https://doc.rust-lang.org/cargo/commands/cargo-publish.html).                                                 |
| push-base   | `./run.sh push-base`         | Push the build container image to the configured container registry (in [config.sh](build-support/shell/run/config.sh)).                                                                                     |
| shell       | `./run.sh shell`             | Sart a Bash shell to run interactive commands.                                                                                                                                                               |
| test        | `./run.sh test`              | Run unit and integration tests with [cargo-test](https://doc.rust-lang.org/cargo/commands/cargo-test.html), and generate coverage report with [grcov](https://github.com/mozilla/grcov).                     |
| update-deps | `./run.sh update-deps`       | Update direct and dev dependencies using [cargo-update](https://doc.rust-lang.org/cargo/commands/cargo-update.html).                                                                                         |

### Adding Commands

Adding a command to the build CLI is designed to be simple, and only requires adding a function named `run-COMMAND` to [run.sh](run.sh).
For example, the following snippet adds the command `vendor` to run [cargo-vendor](https://doc.rust-lang.org/cargo/commands/cargo-vendor.html),
passing through user-provided command line parameters:

```bash
run-vendor() {
    info "Vendoring dependencies"
    cargo vendor "${@}"
}
```

After adding a command, make sure to update the usage in the `print-usage()` function and the [commands table](#build-cli-commands) above.

## Writing Tests

All unit, documentation, and integration tests are run by the built-in Cargo test runner.
See the [Writing Automated Tests](https://doc.rust-lang.org/book/ch11-00-testing.html) chapter in The Book for how write and organize tests.
Also see the [Documentation Tests](https://doc.rust-lang.org/rustdoc/documentation-tests.html) chapter of the `rustdoc` book for how to test documentation examples.
