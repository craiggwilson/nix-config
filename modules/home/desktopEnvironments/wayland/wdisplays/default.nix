{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.wdisplays;
in
{
  options.hdwlinux.desktopEnvironments.wayland.wdisplays = {
    enable = lib.hdwlinux.mkEnableOption "wdisplays" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wdisplays ];
  };
}
