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
  cfg = config.hdwlinux.features.desktop.hyprland.udisks2;
in
{
  options.hdwlinux.features.desktop.hyprland.udisks2 = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable { services.udisks2.enable = true; };
}
