{ lib, pkgs, config, ... }:
let 
  wallpaper = ../assets/wallpapers/bubbles-nord.png;
in {
  hdwlinux.packages.hyprpaper = {
    monitors = [
      { name = "eDP-1"; wallpaper = wallpaper; }
      { name = "DP-5"; wallpaper = wallpaper; }
      { name = "DP-6"; wallpaper = wallpaper; }
    ];
    wallpapers = [ wallpaper ];
  };
}
