{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.niri;
in
{
  options.hdwlinux.desktopManagers.wayland.niri = {
    enable = config.lib.hdwlinux.mkEnableOption "niri" "desktop:niri";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      niri.enable = true;
      uwsm = {
        enable = true;
        waylandCompositors = {
          niri = {
            prettyName = "Niri";
            comment = "Niri managed by UWSM";
            executable = "/run/current-system/sw/bin/niri";
          };
        };
      };
    };

    environment.sessionVariables = {
      GSK_RENDERER = "gl";
    };

    xdg.portal = {
      enable = true;
      config.niri = {
        default = [
          "gtk"
          "wlr"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-wlr
      ];
      xdgOpenUsePortal = true;
    };
  };
}
