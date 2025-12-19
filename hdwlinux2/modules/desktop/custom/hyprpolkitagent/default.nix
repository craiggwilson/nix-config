{
  config.substrate.modules.desktop.custom.hyprpolkitagent = {
    tags = [ "desktop:custom" ];

    homeManager =
      { pkgs, ... }:
      {
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
  };
}

