{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
let
  cfg = config.hdwlinux.features.desktop.hyprland.cliphist;
in
{

  options.hdwlinux.features.desktop.hyprland.cliphist = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.wl-clipboard
    ];

    services.cliphist = {
      enable = true;
    };
  };
}
