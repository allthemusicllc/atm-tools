# Tools for Generating and Working with MIDI Files

## Overview

`atm-cli` is a command line tool for generating and working with MIDI files.
It was purpose-built by All the Music LLC for its mission to enable musicians to make all of their music without the fear of frivolous copyright lawsuits.
All code is released into the public domain via the [Creative Commons Attribution 4.0 International License](http://creativecommons.org/licenses/by/4.0/).
If you're looking for a Rust library to generate and work with simple MIDI files, check out the [libatm crate](../libatm), on which this crate relies.
For more information on All the Music, check out [allthemusic.info](http://allthemusic.info).
For more detailed information about the code, check out the [crate documentation](https://allthemusicllc.github.io/atm-tools/atm/index.html).

## Installation

### Install from GitHub release (preferred method)

Download the binary for your platform from the [latest release](https://github.com/allthemusicllc/atm-tools/releases/latest/).
To verify the SHA-256 hash of the downloaded compressed tarball and executable, run the following commands (on Linux/macOS):

```bash
tar xvzf atm-<platform>.tar.gz
shasum -a 256 -c atm-<platform>.tar.gz.sha256
```

where `<platform>` is the [build target](https://doc.rust-lang.org/nightly/rustc/platform-support.html) for your platform.

### Build from source with Docker

This repository uses a custom build system based on shell (Bash) scripts and Docker.
For more information, read [DEVELOPMENT.md](../../DEVELOPMENT.md).
If you are building on Linux for either Linux or Windows, and once you have the required build dependencies installed,
clone the repo and compile the tool:

```bash
git clone https://github.com/allthemusicllc/atm-tools.git
cd atm-tools
./run.sh build --target <platform> -p atm --release
./target/<platform>/release/atm --help # show usage
```

### Build from source with local Rust toolchain

Make sure the Rust toolchain is installed for your platform by following the [Rust install instructions](https://github.com/allthemusicllc/atm-tools).
Once Rust is installed, [install Cross](https://github.com/cross-rs/cross#installation) to enable easier cross-compilation. 
Finally, clone the repo and compile the tool:

```bash
git clone https://github.com/allthemusicllc/atm-tools.git
cd atm-tools
./run.sh --local build --target <platform> -p atm --release
./target/<platform>/release/atm --help # show usage
```

You can also compile the tool for your platform directly with cargo:

```bash
cargo build -p atm --release
./target/release/atm --help # show usage
```

## Getting Started

To generate a single MIDI file from a melody, use the `gen single` directive:

```bash
atm gen single 'C:4,D:4,E:4,F:4,G:4,A:4,B:4,C:5' test.mid
```

To brute-force generate a range of melodies from a set of notes and with a given length, use one of the `gen *` directives.
The example below will output the melodies to a Gzip-compressed Tar file, with a directory structure that guarantees no more
than 4,096 files per directory.

```bash
atm gen tar-gz -p 2 'C:4,D:4,E:4,F:4,G:4,A:4,B:4,C:5' 8 C4_D4_E4_F4_G4_A4_B4_C5.tar.gz
```

After generating a range of melodies with one of the `gen *` directives (beside `gen single`),
use the `partition` directive to determine which directory a particular melody resides in (A.K.A. to locate the MIDI file containing that melody).

```bash
atm partition -p 2 'C:4,C:4,C:4,C:4,C:4,C:4,C:4,C:5'
```

## Usage

```bash
atm 0.3.0
All The Music, LLC
Tools for generating and working with MIDI files. This app was created as part of an effort to generate by brute-force
billions of melodies, and is tailored for that use case

USAGE:
    atm <SUBCOMMAND>

FLAGS:
    -h, --help       Prints help information
    -V, --version    Prints version information

SUBCOMMANDS:
    estimate     Estimate output size of storage backends to help make informed decisions about which to use
    gen          Generate melodies (MIDI files) and store them in a file/files
    help         Prints this message or the help of the given subcommand(s)
    partition    Generate the partition(s) for a MIDI pitch sequence within a partitioning scheme. If no partition
                 depth is provided, will default to a depth of 1
```
