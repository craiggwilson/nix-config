{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.hyprpaper;
in
{
  options.hdwlinux.desktopManagers.hyprland.hyprpaper = {
    enable = lib.hdwlinux.mkEnableOption "hyprpaper" config.hdwlinux.desktopManagers.hyprland.enable;
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
