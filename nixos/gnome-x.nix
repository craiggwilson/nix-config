{ config, pkgs, lib, ...}: {

  # X Server
  services.xserver.enable = true;

  # Display/Desktop
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = false;
  };

  services.xserver.desktopManager.gnome = {
    enable = true;

    extraGSettingsOverrides = ''
      [org/gnome/desktop/wm/keybindings]
      move-to-workspace-1=['<Shift><Super>1']
      move-to-workspace-2=['<Shift><Super>2']
      move-to-workspace-3=['<Shift><Super>3']
      move-to-workspace-4=['<Shift><Super>4']
      move-to-workspace-down=['<Shift><Super>Down']
      move-to-workspace-up=['<Shift><Super>Up']
      switch-to-workspace-1=['<Super>1']
      switch-to-workspace-2=['<Super>2']
      switch-to-workspace-3=['<Super>3']
      switch-to-workspace-4=['<Super>4']
    '';
  };

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
    gnomeExtensions.paperwm
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.user-themes
    gnomeExtensions.vitals
  ];

  services.udev.packages = with pkgs; [
    gnome.gnome-settings-daemon
  ];
}
