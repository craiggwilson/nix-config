{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.hyprpaper;
in
{
  options.hdwlinux.desktopManagers.wayland.hyprpaper = {
    enable = lib.hdwlinux.mkEnableOption "hyprpaper" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        splash = false;
        ipc = "off";

        preload = "${config.hdwlinux.theme.wallpaper}";
        wallpaper = ",${config.hdwlinux.theme.wallpaper}";
      };
    };
  };
}
