{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.hyprpaper;
  wallpaper = i: if (builtins.length config.hdwlinux.theme.wallpapers) > i then (builtins.elemAt config.hdwlinux.theme.wallpapers i) else (builtins.elemAt config.hdwlinux.theme.wallpapers 0);
in
{
  options.hdwlinux.features.hyprpaper = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprpaper.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ 
      hyprpaper
    ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      ipc = off
      
      ${concatStringsSep "\n" (map (w: "preload = ${w}") config.hdwlinux.theme.wallpapers)}
          
      ${concatStringsSep "\n" (lib.lists.imap0 (i: m: "wallpaper = ${m.name},${wallpaper i}") config.hdwlinux.features.monitors.monitors)}
    '';
  };
}
