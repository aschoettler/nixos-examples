{
  description = "Starter NixOS Configuration";
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

      # CHANGE ME
      # Replace "aarch64-linux" with your architecture
      # Defining "pkgs" at this scope allows it to be re-used in homeConfigurations and nixosConfugurations.
      pkgs-alpha = pkgsFor matrix."aarch64-linux".unstable {
        config.allowUnfree = true;
        overlays = [
          self.overlays.default
          inputs.fenix.overlays.default
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
            bat
            bind.dnsutils
            btop
            curl
            delta
            eza
            fd
            git
            gnused
            helix
            home-manager
            htop
            iputils
            iputils
            just
            lsof
            lsof
            nixfmt-rfc-style
            openssh
            openssh
            openssl
            ripgrep
            rsync
            tldr
            tmux
            vim
            wget

            # (fenix.complete.withComponents [ "rustc" "cargo" "rust-src" "clippy" "rustfmt" ])
          ];
          services.nixos-cli.enable = true;

          # allow vscode (and other programs) to run unpatched binaries:
          # programs.nix-ld.enable = true;

          # shell completions for system packages
          environment.pathsToLink = [ "/share/zsh" ];
        };
      nixosModules.ai =
        { ... }:
        {
          environment.systemPackages = [
            inputs.nix-ai-tools.gemini-cli
            inputs.nix-ai-tools.code # github.com/just-every/code a fork of openai codex
          ];
        };
      # NOTE: Must run this command once for every user:
      #     systemctl --user enable auto-fix-vscode-server.service
      # https://github.com/nix-community/nixos-vscode-server
      nixosModules.vscode-server =
        { ... }:
        {
          imports = [ inputs.vscode-server.nixosModules.default ];
          services.vscode-server.enable = true;
        };
      nixosModules.nix =
        { ... }:
        {
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          system.stateVersion = "24.11";
        };
      nixosModules.system =
        { ... }:
        {
          # CHANGE ME
          # Import your harware-configuration.nix here (or in some other module):
          # imports = [ /etc/nixos/hardware-configuration.nix ];
          # boot.loader.grub.enable = true;
          # boot.loader.grub.device = "/dev/sda";

          # Basic system configuration
          time.timeZone = "UTC";
          i18n.defaultLocale = "en_US.UTF-8";
        };
      nixosModules.starter-user =
        { pkgs, ... }:
        {
          users.users."user" = {
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "networkmanager"
              "docker"
              "wireshark"
            ];
            shell = pkgs.zsh;
            initialPassword = "password";
            openssh.authorizedKeys.keys = [ "ssh-ed25519 <your_ssh_key_here>" ];
          };
          services.getty.autologinUser = "user";
          services.openssh.enable = true;
          services.openssh.settings = {
            PermitRootLogin = "yes";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
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

      homeModules.shell =
        { pkgs, ... }:
        {
          programs.zsh = {
            enable = true;
            history.extended = true;
            enableCompletion = true;
            sessionVariables = {
              BAT_THEME = "OneHalfDark";
              MANPAGER = ''sh -c \"col -bx | ${pkgs.bat}/bin/bat -l man -p\"'';
              MANROFFOPT = "-c";
            };
          };
          programs.starship = {
            enable = true;
            enableZshIntegration = true;
            settings = {
              add_newline = false;
              line_break.disabled = true;
              character = {
                success_symbol = "[->](bold green) ";
                error_symbol = "[✗](bold red) ";
              };
            };
          };
          programs.fzf = {
            enable = true;
            enableZshIntegration = true;
          };
          programs.tmux = {
            enable = true;
            # enables better interactivity with mouse over ssh
            extraConfig = ''set -g mouse on'';
            # plugins = [ pkgs.tmuxPlugins.better-mouse-mode ]; # optional plugin for even more mouse features
          };
          # https://nixos.wiki/wiki/Git
          programs.git = {
            enable = true;
            userName = "Your Name";
            userEmail = "your@email.com";
            delta.enable = true;
          };
          programs.gh.enable = true;
          # programs.gh.gitCredentialHelper.enable = true; # enable gh as git credential helper:
          programs.bat.enable = true;
        };

      homeModules.helix =
        { pkgs, ... }:
        {
          programs.helix = {
            enable = true;
            package = pkgs.helix;

            # Only the tools/servers/formatters needed for nix, md, bash, python, json
            extraPackages = with pkgs; [
              bash-language-server
              marksman
              nixd
              nixfmt-rfc-style
              nodePackages.prettier
              ruff
              rust-analyzer
              taplo-lsp # toml LSP
              vscode-langservers-extracted
              yaml-language-server
              (python3.withPackages (
                ps: with ps; [
                  python-lsp-server
                  python-lsp-ruff
                ]
              ))
            ];
            languages = {
              language-server = {
                bash-language-server.command = "${pkgs.bash-language-server}/bin/bash-language-server";
                marksman.command = "${pkgs.marksman}/bin/marksman";
                ruff = {
                  command = "${pkgs.ruff}/bin/ruff";
                  args = [ "server" ];
                  config.settings.lint = {
                    select = [
                      "D"
                      "E4"
                      "E7"
                      "E9"
                      "F"
                    ];
                    ignore = [
                      "D"
                      "D210"
                      "D103"
                      "D100"
                    ];
                  };
                };
                pylsp.command = "${pkgs.python3.pkgs.python-lsp-server}/bin/pylsp";
                pylsp.config.pylsp = {
                  plugins.pylsp_mypy.enabled = true;
                  plugins.pylsp_mypy.live_mode = true;
                };
                nixd.command = "${pkgs.nixd}/bin/nixd";
                vscode-json-language-server.command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
                taplo-lsp.command = "${pkgs.taplo-lsp}/bin/taplo-lsp";
                rust-analyzer.command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
                yaml-language-server.command = "${pkgs.yaml-language-server}/bin/yaml-language-server";

              };
              language = [
                {
                  name = "bash";
                  auto-format = true;
                  language-servers = [ "bash-language-server" ];
                }
                {
                  name = "markdown";
                  language-servers = [ "marksman" ];
                  comment-tokens = [
                    "-"
                    "*"
                    "- [ ]"
                  ];
                  formatter = {
                    command = "${pkgs.nodePackages.prettier}/bin/prettier";
                    args = [
                      "--stdin-filepath"
                      "file.md"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "python";
                  auto-format = true;
                  language-servers = [
                    "ruff"
                    "pylsp"
                  ];
                  formatter = {
                    command = "${pkgs.ruff}/bin/ruff";
                    args = [
                      "format"
                      "--stdin-filename"
                      "%{buffer_name}"
                    ];
                  };
                }
                {
                  name = "rust";
                  language-servers = [ "rust-analyzer" ];
                  formatter = {
                    command = "${pkgs.rustfmt}/bin/rustfmt";
                    args = [
                      "--edition"
                      "2024"
                    ];
                  };
                }
                {
                  name = "nix";
                  auto-format = true;
                  formatter.command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
                  language-servers = [ "nixd" ];
                }
                {
                  name = "json";
                  language-servers = [ "vscode-json-language-server" ];
                }
                {
                  name = "just";
                  formatter = {
                    command = "${pkgs.just}/bin/just";
                    args = [
                      "--unstable"
                      "--fmt"
                      "-f"
                    ];
                  };
                  auto-format = false;
                }
                {
                  name = "toml";
                  language-servers = [ "taplo-lsp" ];
                  formatter = {
                    command = "${pkgs.taplo}/bin/taplo";
                    args = [
                      "fmt"
                      "-o"
                      "column_width=120"
                      "-"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "yaml";
                  language-servers = [ "yaml-language-server" ];
                  formatter = {
                    command = "${pkgs.nodePackages.prettier}/bin/prettier";
                    args = [
                      "--stdin-filepath"
                      "file.yaml"
                    ];
                  };
                  auto-format = true;
                }
              ];
            };
          };
        };

      # Standalone Home Manager configurations (usable with: `home-manager switch --flake .#<user>`)
      # Declaration of `homeManagerConfiguration`: https://github.com/nix-community/home-manager/blob/master/lib/default.nix
      # Docs: https://nix-community.github.io/home-manager/index.xhtml#sec-upgrade-release-understanding-flake
      homeConfigurations.user = inputs.home-manager-unstable.lib.homeManagerConfiguration {
        pkgs = pkgs-alpha;
        modules = [
          # CHANGE ME (optional)

          # A folder containing a home module file `default.nix`
          # ./per-user/user

          # A home module in a file:
          # ./per-user/user/home.nix

          # Home modules from flakes:
          self.homeModules.shell
          inputs.helix-customization.homeModules.onedark-vibrant

          # An explicit home module:
          (
            { pkgs, ... }:
            {
              home.packages = with pkgs; [
                curl
                gnused
                jq
              ];
              home.stateVersion = "25.05";
              programs.home-manager.enable = true;
            }
          )
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
          # CHANGE ME
          # Replace "aarch64-linux" with your architecture
          system = "aarch64-linux";
          inherit (matrix.${system}.unstable) system_builder;
          pkgs = pkgs-alpha;
        in
        system_builder {
          inherit system pkgs;
          specialArgs = { };
          modules = [
            # CHANGE ME (optional)

            # A file path to a nixos module
            # /etc/nixos/configuration.nix

            # A directory containing a `default.nix` nixos module
            # ./per-host/alpha

            # nixos modules from flakes:
            self.nixosModules.packages
            self.nixosModules.ai
            self.nixosModules.vscode-server
            self.nixosModules.nix
            self.nixosModules.system
            self.nixosModules.starter-user
            self.nixosModules.networking
            # self.nixosModules.darwin-default
            inputs.nixos-cli.nixosModules.nixos-cli

            # An explicit nixos module:
            {
              virtualisation.docker.enable = true; # docker
              # devcontainer.enable = true; # devcontainer CLI
            }
          ];
        };

      templates.basic = {
        description = "Minimal NixOS flake with Home Manager enabled";
        path = ./templates/basic;
      };
    };
}
