{ pkgs, lib, ... }:
{
  imports = [ ] ++ (lib.optional (builtins.pathExists ./secrets.nix) ./secrets.nix);
  home.packages = with pkgs; [
    git
    vim
    helix
    nixfmt-rfc-style
    nixd
    ripgrep
    fd
  ];

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your-email@example.com";
  };

  programs.ssh = {
    extraConfig = ''
      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_git
    '';
  };
}
