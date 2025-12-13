{ config, lib, ... }:
let
  cfg = config.hdwlinux.desktopEnvironments.wayland;
in
{
  options.hdwlinux.desktopEnvironments.wayland = {
    enable = config.lib.hdwlinux.mkEnableOption "wayland" false;
  };

  config = lib.mkIf cfg.enable {
    services.graphical-desktop.enable = true;
  };
}
