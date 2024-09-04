{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.matcha;
in
{
  options.hdwlinux.features.desktop.hyprland.matcha = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [
    #pkgs.hdwlinux.matcha
  ];
}
