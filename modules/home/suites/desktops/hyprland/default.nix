{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.desktops.hyprland;
in
{
  options.hdwlinux.suites.desktops.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable the hyprland desktop environment.";
  };

  config = mkIf cfg.enable {
  	hdwlinux.features = {
      brightnessctl.enable = true;
      cliphist.enable = true;
      dunst.enable = true;
      electronSupport.enable = true;
      gnome-keyring.enable = true;
      grimblast.enable = true;
      hyprland.enable = true;
      hyprpaper.enable = true;
      hyprpicker.enable = true;
      libnotify.enable = true;
      networkmanagerapplet.enable = true;
      pavucontrol.enable = true;
      rofi.enable = true;
      swayidle.enable = true;
      swaylock.enable = true;
      waybar.enable = true;
      wlogout.enable = true;
      udiskie.enable = true;
    };
  };
}