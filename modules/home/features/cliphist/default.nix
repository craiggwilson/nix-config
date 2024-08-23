{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.cliphist;
in
{

  options.hdwlinux.features.cliphist = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config.home.packages =
    with pkgs;
    mkIf cfg.enable [
      cliphist
      wl-clipboard
    ];
}
