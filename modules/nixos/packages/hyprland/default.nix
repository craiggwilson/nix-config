{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.hyprland;
in
{
  options.hdwlinux.packages.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprland.";
    settings = mkOpt attrs { } (mdDoc "Options passed directly to home-manager's `wayland.windowManager.hyprland.settings`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.extraOptions.wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      enableNvidiaPatches = false;
      systemd.enable = false;
      settings = mkAliasDefinitions options.hdwlinux.packages.hyprland.settings;
    };

    programs.hyprland = {
      enable = true;
      enableNvidiaPatches = false; #TODO: check if nvidia is enabled...
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
