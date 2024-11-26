{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.hyprpaper;
  wallpapers = config.hdwlinux.theme.wallpapers;
  monitors = config.hdwlinux.monitors;
  monitorCriteria = m: if m.description != null then "desc:${m.description}" else m.port;
  wallpaperAt =
    i:
    if (builtins.length wallpapers) > i then
      (builtins.elemAt wallpapers i)
    else
      (builtins.elemAt wallpapers 0);
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

        preload = map (w: "${w}") wallpapers;
        wallpaper = lib.lists.imap0 (i: m: "${monitorCriteria m},${wallpaperAt i}") monitors;
      };
    };
  };
}
