# Tools for Generating and Working with MIDI Files

**NOTICE: This repo is under construction and is not ready for use. Once it is ready, and the other repos are archived, this banner will be removed.**

## Overview

## Choice of License

## Packages

TODO

## Commit and Release Verification

All binary releases are hashed using SHA-256 and can be verified using the accompanying `*.sha256` files:

```bash
shasum -a 256 -c <filename>.sha256
```

Our PGP key signature is [CF61C1241EB3A6C85200A93142A82D51E3A76B66](https://keyserver.ubuntu.com/pks/lookup?search=0x42A82D51E3A76B66&op=vindex) and is valid through 2027-04-19.
Commits are signed with this key, and in the future all binary releases will include a signature with this key.

## Dependencies

The `*dependencies` sections in each package's [Cargo.toml](https://doc.rust-lang.org/cargo/reference/manifest.html) manifest have the list of app and dev dependencies.
See [DEVELOPMENT.md](DEVELOPMENT.md) for local development and build dependencies.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for development instructions.

## Contributing/Suggestions

Contributions and suggestions are welcome! To make a feature request, report a bug, or otherwise comment on existing
functionality, please file an issue. For contributions please submit a PR, but make sure to lint, type-check, and test
your code before doing so. Thanks in advance!
