{ inputs, lib, pkgs, ... }:
let
  repoDirectory = "/home/craig/Projects/github.com/craiggwilson/nix-config";
in {
  imports = [
    ./dunst
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

  hdwlinux.home.shellAliases = {
    "start" = "xdg-open";
    "nix-config" = "git -C ${repoDirectory}";
    "nixos-rebuild-switch" = "nix-config add -A . && sudo nixos-rebuild switch --flake ${repoDirectory}?submodules=1";
  };
}
