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

    systemd.user.services.cliphist.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
    systemd.user.services.cliphist-images.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";

    services.cliphist = {
      enable = true;
    };
  };
}
