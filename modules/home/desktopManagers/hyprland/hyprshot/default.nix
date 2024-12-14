{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.hyprshot;
in
{
  options.hdwlinux.desktopManagers.hyprland.hyprshot = {
    enable = lib.hdwlinux.mkEnableOption "hyprshot" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hyprshot ];
  };
}
