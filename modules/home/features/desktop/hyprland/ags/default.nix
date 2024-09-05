{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.desktop.hyprland.ags;
in
{
  options.hdwlinux.features.desktop.hyprland.ags = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = {
    programs.ags = {
      enable = cfg.enable;
      configDir = ./config;
    };
  };
}
