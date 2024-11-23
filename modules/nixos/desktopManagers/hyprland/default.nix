{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland;
in
{
  options.hdwlinux.desktopManagers.hyprland = {
    enable = lib.mkOption {
      description = "Whether to enable hyprland.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "desktop:hyprland" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
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
