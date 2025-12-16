{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.woomer;
in
{
  options.hdwlinux.desktopEnvironments.wayland.woomer = {
    enable = lib.hdwlinux.mkEnableOption "woomer" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.woomer ];
  };
}
