{ config, lib, ... }:

let
  cfg = config.hdwlinux.features.wlsunset;
in
{
  options.hdwlinux.features.wlsunset = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = "32.7942";
      longitude = "96.7655";
    };
  };
}
