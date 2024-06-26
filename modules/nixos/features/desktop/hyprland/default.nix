{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.desktop.hyprland;
in
{
  options.hdwlinux.features.desktop.hyprland = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      config.Hyprland = {
        default = [
          "hyprland"
          "gtk"
          "wlr"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-wlr
      ];
      xdgOpenUsePortal = true;
    };
  };
}
