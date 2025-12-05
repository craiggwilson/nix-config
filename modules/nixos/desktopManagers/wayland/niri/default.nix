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
    hdwlinux.desktopManagers.wayland.enable = lib.mkDefault true;

    programs = {
      uwsm = {
        enable = true;
        waylandCompositors = {
          niri = {
            prettyName = "Niri";
            comment = "Niri managed by UWSM";
            binPath = "/run/current-system/sw/bin/niri-session";
          };
        };
      };
    };

    services.xserver.desktopManager.runXdgAutostartIfNone = true;

    systemd.packages = [ pkgs.niri ];

    environment.sessionVariables = {
      GSK_RENDERER = "gl";
    };

    xdg.portal = {
      enable = true;
      configPackages = [ pkgs.niri ];
      config.niri = {
        default = [
          "gtk"
          "wlr"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-wlr
      ];
      xdgOpenUsePortal = true;
    };
  };
}
