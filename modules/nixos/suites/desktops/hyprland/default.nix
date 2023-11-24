{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.desktops.hyprland;
in
{
  options.hdwlinux.suites.desktops.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprland.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      fonts.enable = true;
      thunar.enable = true;
    };

    programs.hyprland = {
      enable = true;
      enableNvidiaPatches = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ 
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}
