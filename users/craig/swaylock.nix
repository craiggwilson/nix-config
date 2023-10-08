{ lib, pkgs, config, ... }:
{
  hdwlinux.packages.swaylock.settings = {
    ignore-empty-password = true;
    image = "${./assets/wallpaper.jpg}";
    inside-color = "2F6893";
    ring-color = "BFD4F4";
    line-color = "4F87B0";
  };
}
