{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.syshud;
in
{
  options.hdwlinux.desktopManagers.hyprland.syshud = {
    enable = lib.hdwlinux.mkEnableOption "syshud" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.syshud = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "Simple system status indicator.";
        Documentation = "https://github.com/System64fumo/syshud";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.syshud}/bin/syshud";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
