{pkgs, lib, ...}: {
  programs.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  security.pam.services.swaylock.text = "auth include login";

  environment.systemPackages = with pkgs; [
    dunst
    gnome.nautilus
    libnotify
    hyprpaper
    hyprpicker
    networkmanagerapplet
    pamixer
    rofi-wayland
    swaylock
    swayidle
    wl-clipboard
  ];

  programs.waybar.enable = true;
}
