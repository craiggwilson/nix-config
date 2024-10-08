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
  cfg = config.hdwlinux.features.desktop.hyprland.networkmanagerapplet;
in
{
  options.hdwlinux.features.desktop.hyprland.networkmanagerapplet = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ networkmanagerapplet ];
}
