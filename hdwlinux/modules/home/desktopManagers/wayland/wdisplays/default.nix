{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.wdisplays;
in
{
  options.hdwlinux.desktopManagers.wayland.wdisplays = {
    enable = lib.hdwlinux.mkEnableOption "wdisplays" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wdisplays ];
  };
}
