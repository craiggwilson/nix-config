{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.hyprnotify;
in
{
  options.hdwlinux.desktopManagers.hyprland.hyprnotify = {
    enable = lib.hdwlinux.mkEnableOption "hyprpaper" config.hdwlinux.desktopManagers.hyprland.enable;
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
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
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
