{ config, pkgs, lib, ...}: {

  # X Server
  services.xserver.enable = true;

  # Display/Desktop
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  services.xserver.desktopManager.gnome.enable = true;

    # Keymap
  services.xserver.layout = "us";
  
  # Packages
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    gnome.geary
    gnome.cheese
    gnome.gnome-music
    gnome.gedit
    gnome.epiphany
    gnome.evince
    gnome.gnome-characters
    gnome.totem
    gnome.tali
    gnome.iagno
    gnome.hitori
    gnome.atomix
  ];

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.adwaita-icon-theme
    gnome.gnome-tweaks
    gnome.networkmanager-l2tp

    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.gsconnect
    gnomeExtensions.openweather
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.user-themes
    gnomeExtensions.vitals
  ];

  services.udev.packages = with pkgs; [
    gnome.gnome-settings-daemon
  ];
}

