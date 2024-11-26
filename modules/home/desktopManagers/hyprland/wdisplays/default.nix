{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.wdisplays;
in
{
  options.hdwlinux.desktopManagers.hyprland.wdisplays = {
    enable = lib.hdwlinux.mkEnableOption "wdisplays" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wdisplays ];
  };
}
