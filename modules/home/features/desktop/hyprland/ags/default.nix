{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.ags;
in
{
  options.hdwlinux.features.desktop.hyprland.ags = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs.ags = {
      enable = true;
      configDir = ./src;
    };
  };
}
