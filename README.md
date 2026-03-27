# cursor-cli-nix

Package Cursor Agent CLI as a Nix flake.

## Install

```console
nix profile add github:Riatre/cursor-cli-nix#cursor-agent
```

## What this packages

This packages the upstream Cursor Agent CLI bundle from:

`https://downloads.cursor.com/lab/2026.03.25-933d5a6/linux/x64/agent-cli-package.tar.gz`

The package keeps Cursor's bundled Node runtime and native addons intact, then
patches the ELF binaries for Nix.

## Supported platform

- `x86_64-linux`
