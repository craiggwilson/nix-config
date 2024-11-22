{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.hyprpolkitagent;
in
{
  options.hdwlinux.desktopManagers.hyprland.hyprpolkitagent = {
    enable = lib.mkOption {
      description = "Whether to enable hyprpolkitagent.";
      type = lib.types.bool;
      default = config.hdwlinux.desktopManagers.hyprland.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
    systemd.user.services.hyprpolkitagent = {
      description = "hyprland-polkit-agent";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
