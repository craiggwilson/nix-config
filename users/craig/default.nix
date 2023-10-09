{ inputs, lib, ... }:
{
  imports = [
    ./gtk
    ./hyprland
    ./hyprpaper
    ./starship
    ./swaylock
    ./vscode
    ./waybar
  ] ++ lib.optional (builtins.pathExists ../../private/craig/default.nix) ../../private/craig;
}
