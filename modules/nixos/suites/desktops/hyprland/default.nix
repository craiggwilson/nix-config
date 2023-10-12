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
  	hdwlinux.packages = {
      brightnessctl.enable = true;
      cliphist.enable = true;
      dunst.enable = true;
      fonts.enable = true;
      electronSupport.enable = true;
      hyprland.enable = true;
      hyprpaper.enable = true;
      hyprpicker.enable = true;
      libnotify.enable = true;
      networkmanagerapplet.enable = true;
      thunar.enable = true;
      pavucontrol.enable = true;
      rofi.enable = true;
      swayidle.enable = true;
      swaylock.enable = true;
      waybar.enable = true;
      udiskie.enable = true;
    };
  };
}
