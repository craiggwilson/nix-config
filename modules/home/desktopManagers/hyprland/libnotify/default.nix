{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.libnotify;
in
{
  options.hdwlinux.desktopManagers.hyprland.libnotify = {
    enable = lib.hdwlinux.mkEnableOption "libnotify" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.libnotify ];
  };
}
