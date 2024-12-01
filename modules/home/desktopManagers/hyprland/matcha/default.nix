{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.matcha;
in
{
  options.hdwlinux.desktopManagers.hyprland.matcha = {
    enable = lib.hdwlinux.mkEnableOption "matcha" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hdwlinux.matcha ];
  };
}
