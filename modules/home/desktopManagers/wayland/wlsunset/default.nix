{ config, lib, ... }:

let
  cfg = config.hdwlinux.desktopManagers.wayland.wlsunset;
in
{
  options.hdwlinux.desktopManagers.wayland.wlsunset = {
    enable = lib.hdwlinux.mkEnableOption "wlsunset" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = "32.7942";
      longitude = "-96.7655";
    };
  };
}
