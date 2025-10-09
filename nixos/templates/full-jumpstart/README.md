# Jumpstart Flake

This flake contains several nixos & home-manager modules to get your brand new system up and runnign with a handfull of developer tools.
The flake is organized into several nixos modules which can be added / removed individually from the `nixosConfigurations.*` settings for your system.

## 0. Download This Flake:

    nix flake init -t 'github:aschoettler/nixos-examples?dir=nixos#full'

## 1. Hardware Configuration

    # Copy your existing configuration.nix & hardware-configuration.nix
    cp /etc/nixos/*configuration.nix .

    # OR regenerate it here
    nixos-generate-config --dir .

## 2. Enable flakes via alias

Source the shell script until your config enables flakes:

    # create `nixf` alias
    # alias nixf="nix --extra-experimental-features 'nix-command flakes'"
    . ./nixenv.sh

## 3. Update the flake with your username, hostname, and architecture

    # use the alias
    nixf shell nixpkgs#vim

Search for "CHANGE ME" in the flake:

- Replace `"user"` with your username
- Replace `"aarch64-linux"` to your architecture
- Replace `"alpha"` with your hostname

## 4. Apply the configuration

    # On the first run, specify your hostname:
    sudo nixos-rebuild --flake .#<hostname> -L --show-trace switch
    home-manager --flake .#<username> switch

    # After the first run:
    just rebuild
