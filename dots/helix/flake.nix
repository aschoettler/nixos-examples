{
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";

  outputs =
    { self }:
    {
      ### This nixos module imports all the themes in the ./helix-themes folder. Home manager will symlink them under ~/.config/helix/themes/.
      ### Once you've imported the module, set `programs.helix.theme = "onedark-vibrant"`
      nixosModules.helix-themes =
        { lib, ... }:
        let
          themeDir = ./helix-themes;
          themeFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".toml" name) (
            builtins.readDir themeDir
          );
          themes = builtins.listToAttrs (
            map (
              file:
              let
                themeName = lib.removeSuffix ".toml" file;
                themePath = builtins.toPath "${themeDir}/${file}";
                theme = builtins.fromTOML (builtins.readFile themePath);
              in
              {
                name = themeName;
                value = lib.mkDefault theme;
              }
            ) (builtins.attrNames themeFiles)
          );
        in
        {
          options = { };
          config = {
            programs.helix.themes = themes;
          };
        };
    };
}
