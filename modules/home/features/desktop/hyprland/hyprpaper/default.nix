{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.hyprpaper;
  wallpapers = config.hdwlinux.theme.wallpapers;
  monitors = config.hdwlinux.monitors.monitors;
  monitorCriteria = m: if m.description != null then "desc:${m.description}" else m.port;
  wallpaperAt =
    i:
    if (builtins.length wallpapers) > i then
      (builtins.elemAt wallpapers i)
    else
      (builtins.elemAt wallpapers 0);
in
{
  options.hdwlinux.features.desktop.hyprland.hyprpaper = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ hyprpaper ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      splash = false
      ipc = off

      ${lib.concatStringsSep "\n" (map (w: "preload = ${w}") wallpapers)}
          
      ${lib.concatStringsSep "\n" (
        lib.lists.imap0 (i: m: "wallpaper = ${monitorCriteria m},${wallpaperAt i}") monitors
      )}
    '';
  };
}
