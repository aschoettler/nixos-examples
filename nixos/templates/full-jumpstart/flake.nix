{
  description = "Simple NixOS Configuration";
  inputs = {
    # nixpkgs / home-manager / nix-darwin
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin-stable = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixos-stable";
    };
    nix-darwin-unstable = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixos-stable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos-unstable";
    };
    nix-ld.url = "github:nix-community/nix-ld";
    # Things for rust development
    naersk.url = "github:nix-community/naersk";
    fenix.url = "github:nix-community/fenix";
    # ai tools
    just-every-code.url = "github:just-every/code";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    # Other
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    flake-utils.url = "github:numtide/flake-utils";
    # cli tool `nixos` useful for browsing options
    nixos-cli.url = "github:nix-community/nixos-cli";
    nix4vscode.url = "github:nix-community/nix4vscode";
    # Personal
    helix-customization.url = "github:aschoettler/nixos-examples?dir=dots/helix";
  };
  outputs =
    inputs@{ self, ... }:
    let
      matrix = {
        "aarch64-linux".unstable = {
          system = "aarch64-linux";
          nixpkgs = inputs.nixos-unstable;
          home-manager-module = inputs.home-manager-unstable.nixosModules.home-manager;
          system_builder = inputs.nixos-unstable.lib.nixosSystem;
        };
        "aarch64-linux".stable = {
          system = "aarch64-linux";
          nixpkgs = inputs.nixos-stable;
          home-manager-module = inputs.home-manager-stable.nixosModules.home-manager;
          system_builder = inputs.nixos-stable.lib.nixosSystem;
        };
        "aarch64-darwin".unstable = {
          system = "aarch64-darwin";
          nixpkgs = inputs.nixos-unstable;
          home-manager-module = inputs.home-manager-unstable.darwinModules.home-manager;
          system_builder = inputs.nix-darwin-unstable.lib.darwinSystem;
        };
        "aarch64-darwin".stable = {
          system = "aarch64-darwin";
          nixpkgs = inputs.nixos-stable;
          home-manager-module = inputs.home-manager-stable.darwinModules.home-manager;
          system_builder = inputs.nix-darwin-stable.lib.darwinSystem;
        };
      };

      pkgsFor = (
        matrixEntry: nixpkgsConfig:
        import matrixEntry.nixpkgs ({ inherit (matrixEntry) system; } // nixpkgsConfig)
      );

      pkgs-alpha = pkgsFor matrix."aarch64-linux".unstable {
        config.allowUnfree = true;
        overlays = [
          # inputs.fenix.overlays.default
          self.overlays.default
          # inputs.nix4vscode.overlays.forVscode
        ];
      };

    in
    {
      # NIXOS MODULES
      # Feel free to modify / add / remove any `nixosModules.*` block or copy-paste their contents to your own module files (called via `imports = [ ... ]`)
      nixosModules.packages =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            git
            helix
            vim
            ripgrep
            curl
            bat
            eza
            openssh
            iputils
            home-manager
            htop
            tmux
            lsof
            bind.dnsutils
            # (fenix.complete.withComponents [ "rustc" "cargo" "rust-src" "clippy" "rustfmt" ])
          ];
        };
      nixosModules.ai =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            inputs.nix-ai-tools.gemini-cli
            inputs.nix-ai-tools.code # github.com/just-every/code a fork of openai codex
          ];
        };
      nixosModules.nix = {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        system.stateVersion = "24.11";
      };
      nixosModules.system =
        { ... }:
        {
          # Import your harware-configuration.nix here (or in some other module):
          # imports = [
          #   /etc/nixos/hardware-configuration.nix
          # ];
          # Basic system configuration
          time.timeZone = "UTC";
          i18n.defaultLocale = "en_US.UTF-8";
          # Boot configuration
          boot.loader.grub.enable = true;
          boot.loader.grub.device = "/dev/sda";
        };
      nixosModules.starter-user =
        { ... }:
        {
          users.users."user" = {
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "networkmanager"
              "docker"
              "wireshark"
            ];
            initialPassword = "password";
            openssh.authorizedKeys.keys = [ "ssh-ed25519 <your_ssh_key_here>" ];
          };
          services.getty.autologinUser = "user";
          services.openssh.enable = true;
          services.openssh.ports = [ 22 ];
          services.openssh.settings = {
            PermitRootLogin = "yes";
            PasswordAuthentication = true;
            KbdInteractiveAuthentication = false;
            PermitEmptyPasswords = "no";
          };
          networking.firewall.allowedTCPPorts = [ 22 ];
        };
      nixosModules.networking =
        { ... }:
        {
          networking = {
            useNetworkd = true;
            useDHCP = true;
            networkmanager.enable = false;
            firewall.enable = true;
          };
          # Enable IP Forwarding
          boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv6.conf.all.forwarding" = 1;
          };
        };
      nixosModules.darwin-default =
        { ... }:
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          nix.settings.experimental-features = "nix-command flakes";
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;
        };

      # Standalone Home Manager configurations (usable with: home-manager switch --flake .#<user>)
      # declaration of `homeManagerConfiguration`: https://github.com/nix-community/home-manager/blob/master/lib/default.nix
      homeConfigurations.user = inputs.home-manager-unstable.lib.homeManagerConfiguration {
        pkgs = pkgs-alpha;
        modules = [
          # ./per-user/user
          inputs.helix-customization.homeModules.helix-themes
        ];
        extraSpecialArgs = { };
      };

      overlays.default = final: prev: {
        inherit (import inputs.nixos-unstable { system = prev.stdenv.system; })
          # always use latest versions of these packages
          _1password-cli
          devcontainer
          gitea
          rust-analyzer
          wezterm
          wireguard-tools
          ;
      };

      nixosConfigurations.alpha =
        let
          system = "aarch64-linux";
          inherit (matrix.${system}.unstable) system_builder;
          pkgs = pkgs-alpha;
        in
        system_builder {
          inherit system pkgs;
          specialArgs = {
            inherit (inputs) vscode-server;
          };
          modules = [
            # /etc/nixos/configuration.nix # <-- a file path to a nixos module
            # ./per-host/alpha # <-- a file path to a nixos module
            self.nixosModules.packages
            # self.nixosModules.ai
            self.nixosModules.nix
            self.nixosModules.system
            self.nixosModules.starter-user
            self.nixosModules.networking
            # self.nixosModules.darwin-default
            inputs.nixos-cli.nixosModules.nixos-cli
            {
              # virtualisation.docker.enable = true;
            }
          ];
        };

      templates.basic = {
        description = "Minimal NixOS flake with Home Manager enabled";
        path = ./templates/basic;
      };
    };
}
