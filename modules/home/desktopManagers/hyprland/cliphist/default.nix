{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.desktopManagers.hyprland.cliphist;
in
{

  options.hdwlinux.desktopManagers.hyprland.cliphist = {
    enable = lib.hdwlinux.mkEnableOption "cliphist" config.hdwlinux.desktopManagers.hyprland.enable;
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
