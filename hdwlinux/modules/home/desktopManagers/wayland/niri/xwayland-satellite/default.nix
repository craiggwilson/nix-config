{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.desktopManagers.wayland.niri.xwayland-satellite;
in
{
  options.hdwlinux.desktopManagers.wayland.niri.xwayland-satellite = {
    enable = config.lib.hdwlinux.mkEnableOption "xwayland-satellite" config.hdwlinux.desktopManagers.wayland.niri.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.xwayland-satellite.override { withSystemd = false; }) # Niri automatically runs this when xwayland support is required
    ];
  };
}
