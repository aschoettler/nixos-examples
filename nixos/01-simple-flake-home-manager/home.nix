{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      git
      vim
      helix
      nixfmt-rfc-style
      nixd
      ripgrep
      fd
    ];
  };
}
