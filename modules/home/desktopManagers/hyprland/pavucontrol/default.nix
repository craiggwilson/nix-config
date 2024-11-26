{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.pavucontrol;
in
{
  options.hdwlinux.desktopManagers.hyprland.pavucontrol = {
    enable = lib.hdwlinux.mkEnableOption "pavucontrol" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.pavucontrol ];
  };
}
