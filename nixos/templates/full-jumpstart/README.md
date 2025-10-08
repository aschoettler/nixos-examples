# Jumpstart Flake

This flake contains

# Usage

Download me!

```bash
# Download this flake and sibling files:
nix flake init -t 'github:aschoettler/nixos-examples?dir=nixos#full'
```

Source the shell script (useful before your config enables flakes)

```bash
# Source the shell script until you have flakes enabled via config
. ./nixenv.sh
```

**Update the flake with your architecture, hostname, username, and hardware configuration**:

```bash
# Edit the flake
nixf shell nixpkgs#vim && vi flake.nix
```

Search for "CHANGE ME" in the flake:

- Change `"aarch64-linux"` to your architecture
- Change the hostname `alpha` to your desired hostname
- Change the username `user` to your username **IMPORTANT**
- Import `hardware-configuration.nix` -OR- run `nixos-generate-config --dir .` and add import the local version.

# Building

Use `just rebuild` or `just test`.

Test for syntax errors / nix build-time errors without touching the system:

    nix build -L .#nixosConfigurations.alpha.config.system.build.toplevel
