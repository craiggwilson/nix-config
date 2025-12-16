{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.hyprland;
in
{
  options.hdwlinux.desktopEnvironments.wayland.hyprland = {
    enable = config.lib.hdwlinux.mkEnableOption "hyprland" "desktop:hyprland";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.desktopEnvironments.wayland.enable = lib.mkDefault true;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    environment.sessionVariables = {
      GSK_RENDERER = "gl";
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
