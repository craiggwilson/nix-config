{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.upower;
in
{
  options.hdwlinux.features.desktop.hyprland.upower = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.upower.enable = true;
  };
}
