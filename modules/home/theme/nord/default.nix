{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
let
  cfg = config.hdwlinux.theme.nord;
  wallpaper = ./assets/wild.png;
in
{

  options.hdwlinux.theme.nord = {
    enable = config.lib.hdwlinux.features.mkEnableOption "nord" "theming:nord";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.theme = {
      enable = lib.mkDefault true;
      name = "nord";
      colors = inputs.themes.nord;
      dark = true;
      wallpapers = [ wallpaper ];
    };

    gtk = {
      cursorTheme = lib.mkDefault {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
      };
      iconTheme = lib.mkDefault {
        name = "Nordzy-dark";
        package = pkgs.nordzy-icon-theme;
      };
    };
  };
}
