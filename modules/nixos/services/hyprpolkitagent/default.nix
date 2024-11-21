{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.hyprpolkitagent;
in
{
  options.hdwlinux.services.hyprpolkitagent = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
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
