{ config, lib, ... }:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.wlsunset;
in
{
  options.hdwlinux.desktopManagers.hyprland.wlsunset = {
    enable = lib.hdwlinux.mkEnableOption "wlsunset" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = "32.7942";
      longitude = "-96.7655";
    };
  };
}
