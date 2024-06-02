{ config, lib, ... }:

let cfg = config.hdwlinux.features.redshift;
in
{
  options.hdwlinux.features.redshift = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.redshift = {
      enable = true;
      provider = "geoclue2";
      tray = true;
    };
  };
}
