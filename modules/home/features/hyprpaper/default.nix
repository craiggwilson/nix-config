{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.hyprpaper;
  wallpapers = config.hdwlinux.theme.wallpapers;
  monitors = config.hdwlinux.features.monitors.monitors;
  wallpaperAt =
    i:
    if (builtins.length wallpapers) > i then
      (builtins.elemAt wallpapers i)
    else
      (builtins.elemAt wallpapers 0);
in
{
  options.hdwlinux.features.hyprpaper = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ hyprpaper ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      spash = false
      ipc = off

      ${lib.concatStringsSep "\n" (map (w: "preload = ${w}") wallpapers)}
          
      ${lib.concatStringsSep "\n" (
        lib.lists.imap0 (i: m: "wallpaper = ${m.name},${wallpaperAt i}") monitors
      )}
    '';
  };
}
