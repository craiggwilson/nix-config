{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.hyprpaper;
  wallpapers = config.hdwlinux.theme.wallpapers;
  monitors = config.hdwlinux.features.monitors.monitors;
  wallpaperAt = i: if (builtins.length wallpapers) > i then (builtins.elemAt wallpapers i) else (builtins.elemAt wallpapers 0);
in
{
  options.hdwlinux.features.hyprpaper = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ 
      hyprpaper
    ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = off
      spash = false
      
      ${concatStringsSep "\n" (map (w: "preload = ${w}") wallpapers)}
          
      ${concatStringsSep "\n" (lib.lists.imap0 (i: m: "wallpaper = ${m.name},${wallpaperAt i}") monitors)}
    '';
  };
}
