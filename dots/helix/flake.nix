{
  outputs =
    { self }:
    {
      # This home-manager module makes all the themes in the ./helix-themes folder available to helix.
      # Home manager will symlink them under ~/.config/helix/themes/.
      # Add this module to your home-manager imports then set `programs.helix.settings.theme = "onedark-vibrant"`
      homeModules.helix-themes =
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
      # This home-manager module imoprts and applies the "onedark-vibrant" theme
      homeModules.onedark-vibrant =
        { lib, ... }:
        {
          imports = [ self.homeModules.helix-themes ];
          programs.helix.enable = true;
          programs.helix.settings.theme = lib.mkDefault "onedark-vibrant";
        };
    };
}
