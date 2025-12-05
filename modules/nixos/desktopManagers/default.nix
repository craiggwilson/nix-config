{ config, lib, ... }:
let
  cfg = config.hdwlinux.desktopManagers.wayland;
in
{
  options.hdwlinux.desktopManagers.wayland = {
    enable = config.lib.hdwlinux.mkEnableOption "wayland" false;
  };

  config = lib.mkIf cfg.enable {
    services.graphical-desktop.enable = true;
  };
}
