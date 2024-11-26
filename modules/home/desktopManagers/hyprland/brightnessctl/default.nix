{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.brightnessctl;
in
{
  options.hdwlinux.desktopManagers.hyprland.brightnessctl = {
    enable = lib.hdwlinux.mkEnableOption "brightnessctl" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.brightnessctl ];
  };
}
