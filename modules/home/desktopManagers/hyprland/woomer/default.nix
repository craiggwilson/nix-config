{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.woomer;
in
{
  options.hdwlinux.desktopManagers.hyprland.woomer = {
    enable = lib.hdwlinux.mkEnableOption "woomer" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.woomer ];
  };
}
