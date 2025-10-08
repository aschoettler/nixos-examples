# Jumpstart Flake

This flake contains

# Usage

Download me!

```bash
# Download this flake and sibling files:
nix flake init -t 'github:aschoettler/nixos-examples?dir=nixos#full'
# If your system is BRAND new:
nix --extra-experimental-features nix-command flakes
```

**Then, change the following**:

Search for "CHANGE ME" in the flake:

- Change `"aarch64-linux"` to your architecture in `pkgs-alpha = ...` and in `nixosConfigurations.alpha = ...`
- Un-comment the line `imports = [ /etc/nixos/hardware-configuration.nix ];`. Optionally move it into your tree.

# Building

Use `just rebuild`, `just test`

Test for syntax errors / nix build-time errors without touching the system:

    nix build -L .#nixosConfigurations.alpha.config.system.build.toplevel
