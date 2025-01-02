{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.wl-screenrec;
in
{
  options.hdwlinux.desktopManagers.hyprland.wl-screenrec = {
    enable = lib.hdwlinux.mkEnableOption "wl-screenrec" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wl-screenrec ];
  };
}
