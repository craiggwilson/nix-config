{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.desktop.hyprland;
in
{
  options.hdwlinux.suites.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable the hyprland desktop environment.";
  };

  config = mkIf cfg.enable {
  	hdwlinux.packages = {
	  dunst.enable = true;
	  fonts.enable = true;
	  electronSupport.enable = true;
	  hyprland.enable = true;
	  hyprpaper.enable = true;
	  hyprpicker.enable = true;
	  libnotify.enable = true;
	  networkmanagerapplet.enable = true;
	  nautilus.enable = true;
	  pavucontrol.enable = true;
	  rofi.enable = true;
	  swayidle.enable = true;
	  swaylock.enable = true;
	  waybar.enable = true;
	  wl-clipboard.enable = true;
    };
  };
}