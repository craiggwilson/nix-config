{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.hyprnotify;
in
{
  options.hdwlinux.features.desktop.hyprland.hyprnotify = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [ pkgs.hyprnotify ];
}
