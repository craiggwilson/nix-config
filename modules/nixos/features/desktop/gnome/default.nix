{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.desktop.gnome;
in
{
  options.hdwlinux.features.desktop.gnome = with types; {
    enable = mkEnableOpt [ "desktop:gnome" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        cheese
        gnome-music
        gnome-terminal
        epiphany
        geary
        gnome-characters
        totem
        hitori
        atomix
      ]);

    environment.systemPackages = with pkgs; [ gnome.gnome-tweaks ];
  };
}
