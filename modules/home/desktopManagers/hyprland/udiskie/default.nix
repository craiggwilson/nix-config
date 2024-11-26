{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.udiskie;
in
{
  options.hdwlinux.desktopManagers.hyprland.udiskie = {
    enable = lib.hdwlinux.mkEnableOption "udiskie" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = true;
      tray = "auto";
    };
  };
}
