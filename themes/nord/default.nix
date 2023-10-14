{ inputs, lib, pkgs, ... }:
{
  imports = [
    ./dunst
    ./gtk
    ./hyprland
    ./starship
    ./swaylock
    ./vscode
    ./waybar
  ];
}
