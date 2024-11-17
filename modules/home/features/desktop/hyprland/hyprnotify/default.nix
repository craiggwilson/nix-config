{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.hyprnotify;
in
{
  options.hdwlinux.features.desktop.hyprland.hyprnotify = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hyprnotify ];

    systemd.user.services.hyprnotify = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "DBus Implementation of Freedesktop Notification spec for 'hyprctl notify'";
        Documentation = [
          "https://github.com/codelif/hyprnotify"
        ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session-pre.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.hyprnotify}/bin/hyprnotify --no-sound";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
