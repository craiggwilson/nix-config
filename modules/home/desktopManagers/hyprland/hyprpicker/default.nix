{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.hyprpicker;
in
{
  options.hdwlinux.desktopManagers.hyprland.hyprpicker = {
    enable = lib.hdwlinux.mkEnableOption "hyprpicker" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hyprpicker ];
  };
}
