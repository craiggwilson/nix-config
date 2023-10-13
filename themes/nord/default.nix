{ inputs, lib, pkgs, ... }:
{
  imports = [
    ./dunst
    ./gtk
    ./hyprland
    ./kitty
    ./rofi
    ./starship
    ./swaylock
    ./vscode
    ./waybar
  ];
}
