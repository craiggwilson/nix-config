{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.gnome;
in
{
  options.hdwlinux.features.desktop.gnome = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:gnome" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        xkb.layout = "us";
        desktopManager.gnome.enable = true;
        displayManager.gdm = {
          enable = true;
          wayland = true;
        };
      };
      libinput.enable = true;
    };

    environment.gnome.excludePackages = [
      pkgs.gnome-photos
      pkgs.gnome-tour
      pkgs.cheese
      pkgs.gnome-music
      pkgs.gnome-terminal
      pkgs.epiphany
      pkgs.geary
      pkgs.gnome-characters
      pkgs.totem
      pkgs.hitori
      pkgs.atomix
    ];

    environment.systemPackages = [ pkgs.gnome-tweaks ];
  };
}
