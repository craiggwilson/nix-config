{ inputs, lib, ... }:
{
  imports = [
    ./hyprland.nix
    ./hyprpaper.nix
    ./starship.nix
    ./swaylock.nix
    ./vscode.nix
    ./waybar.nix
  ] ++ lib.optional (builtins.pathExists ../../private/craig/default.nix) ../../private/craig;
}
