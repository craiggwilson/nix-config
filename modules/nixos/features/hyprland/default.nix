{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.hyprland;
in
{
  options.hdwlinux.features.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprland.";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      enableNvidiaPatches = builtins.elem "nvidia" config.services.xserver.videoDrivers;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [ 
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}
