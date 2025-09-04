{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.hyprpolkitagent;
in
{
  options.hdwlinux.desktopManagers.wayland.hyprpolkitagent = {
    enable = lib.mkOption {
      description = "Whether to enable hyprpolkitagent.";
      type = lib.types.bool;
      default = config.hdwlinux.desktopManagers.wayland.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.hyprpolkitagent = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "hypr-polkit-agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
