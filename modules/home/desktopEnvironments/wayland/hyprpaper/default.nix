{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.hyprpaper;
in
{
  options.hdwlinux.desktopEnvironments.wayland.hyprpaper = {
    enable = lib.hdwlinux.mkEnableOption "hyprpaper" config.hdwlinux.desktopEnvironments.wayland.enable;
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
