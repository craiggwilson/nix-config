{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.udiskie;
in
{
  options.hdwlinux.desktopManagers.wayland.udiskie = {
    enable = lib.hdwlinux.mkEnableOption "udiskie" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = true;
      tray = "auto";
    };
  };
}
