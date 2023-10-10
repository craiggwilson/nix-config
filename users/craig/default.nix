{ inputs, lib, pkgs, ... }:
{
  imports = [
    ./gtk
    ./hyprland
    ./hyprpaper
    ./kitty
    ./rofi
    ./starship
    ./swaylock
    ./vscode
    ./waybar
  ] ++ lib.optional (builtins.pathExists ../../private/craig/default.nix) ../../private/craig;
}
