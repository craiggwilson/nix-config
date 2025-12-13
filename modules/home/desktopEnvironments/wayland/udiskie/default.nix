{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.udiskie;
in
{
  options.hdwlinux.desktopEnvironments.wayland.udiskie = {
    enable = lib.hdwlinux.mkEnableOption "udiskie" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = true;
      tray = "auto";
    };
  };
}
