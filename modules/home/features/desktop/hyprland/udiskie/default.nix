{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.desktop.hyprland.udiskie;
in
{
  options.hdwlinux.features.desktop.hyprland.udiskie = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config.services.udiskie = mkIf cfg.enable {
    enable = true;
    automount = true;
    tray = "auto";
  };
}
