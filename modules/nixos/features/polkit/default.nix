{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.polkit;
in
{
  options.hdwlinux.features.polkit = with types; {
    enable = mkBoolOpt false "Whether or not to enable polkit.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        polkit_gnome
    ];

    security.polkit.enable = true;

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
      };
    };
  };
}
