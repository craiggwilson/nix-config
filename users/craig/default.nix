{ inputs, lib, pkgs, ... }:
{
  imports = [
    ./gtk
    ./hyprland
    ./hyprpaper
    ./rofi
    ./starship
    ./swaylock
    ./vscode
    ./waybar
  ] ++ lib.optional (builtins.pathExists ../../private/craig/default.nix) ../../private/craig;
}
