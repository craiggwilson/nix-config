{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.grimblast;
in
{
  options.hdwlinux.desktopManagers.hyprland.grimblast = {
    enable = lib.hdwlinux.mkEnableOption "grimblast" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.grimblast ];
  };
}
