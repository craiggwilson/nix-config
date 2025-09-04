{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.woomer;
in
{
  options.hdwlinux.desktopManagers.wayland.woomer = {
    enable = lib.hdwlinux.mkEnableOption "woomer" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.woomer ];
  };
}
