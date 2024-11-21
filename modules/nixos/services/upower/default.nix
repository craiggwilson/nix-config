{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.upower;
in
{
  options.hdwlinux.services.upower = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.upower.enable = true;
  };
}
