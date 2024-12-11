{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.cava;
in
{
  options.hdwlinux.desktopManagers.hyprland.cava = {
    enable = lib.hdwlinux.mkEnableOption "cava" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cava ];
  };
}
