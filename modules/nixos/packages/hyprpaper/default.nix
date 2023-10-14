{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.hyprpaper;
in
{
  options.hdwlinux.packages.hyprpaper = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprpaper.";
    monitors = mkOption {
      default = [ ];
      description = "Monitors and their wallpaper.";
      type = listOf (submodule {
        options = {
          name = mkOption { type = str; };
          wallpaper = mkOption { type = path; };
        };
      });
    };
  };

  config.hdwlinux.home = mkIf cfg.enable {
    packages = with pkgs; [ 
      hyprpaper
    ];

    configFile."hypr/hyprpaper.conf".text = ''
      ipc = off
      
      ${concatStringsSep "\n" (map (monitor: "preload = ${monitor.wallpaper}") (lib.hdwlinux.uniqueBy (f: "${f.wallpaper}") cfg.monitors))}
          
      ${concatStringsSep "\n" (map (monitor: "wallpaper = ${monitor.name},${monitor.wallpaper}") cfg.monitors)}
    '';
  };
}
