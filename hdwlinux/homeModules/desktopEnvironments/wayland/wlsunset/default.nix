{ config, lib, ... }:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.wlsunset;
in
{
  options.hdwlinux.desktopEnvironments.wayland.wlsunset = {
    enable = lib.hdwlinux.mkEnableOption "wlsunset" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = "32.7942";
      longitude = "-96.7655";
    };
  };
}
