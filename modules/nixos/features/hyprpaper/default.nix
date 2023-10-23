{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.hyprpaper;
in
{
  options.hdwlinux.features.hyprpaper = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprpaper.";
  };

  config.hdwlinux.home = mkIf cfg.enable {
    packages = with pkgs; [ 
      hyprpaper
    ];

    configFile."hypr/hyprpaper.conf".text = ''
      ipc = off
      
      ${concatStringsSep "\n" (map (monitor: "preload = ${monitor.wallpaper}") (lib.hdwlinux.uniqueBy (f: "${f.wallpaper}") config.hdwlinux.features.monitors.monitors))}
          
      ${concatStringsSep "\n" (map (monitor: "wallpaper = ${monitor.name},${monitor.wallpaper}") config.hdwlinux.features.monitors.monitors)}
    '';
  };
}
