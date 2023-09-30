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

  # programs.dconf.settings = {
  #   "org/gnome/desktop/wm/keybindings" = {
  #     move-to-workspace-1 = [ "<Control><Super>1 "];
  #     move-to-workspace-2 = [ "<Control><Super>2 "];
  #     move-to-workspace-3 = [ "<Control><Super>3" ];
  #     move-to-workspace-4 = [ "<Control><Super>4" ];
  #     move-to-workspace-down = [ "<Control><Super>Down" ];
  #     move-to-workspace-up = [ "<Control><Super>Up "];
  #     switch-to-workspace-1 = [ "<Super>1" ];
  #     switch-to-workspace-2 = [ "<Super>2" ];
  #     switch-to-workspace-3 = [ "<Super>3" ];
  #     switch-to-workspace-4 = [ "<Super>4" ];
  #   };

  #   "/org/gnome/shell" = {
  #     enabled-extensions = [
  #         "appindicatorsupport@rgcjonas.gmail.com"     
  #         "caffeine@patapon.info"
  #         "clipboard-indicator@tudmotu.com"
  #         "drive-menu@gnome-shell-extensions.gcampax.github.com"
  #         "gsconnect@andyholmes.github.io"
  #         "openweather-extension@jenslody.de"
  #         "Vitals@CoreCoding.com"
  #         "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
  #     ];
  #   };
  # };
}

