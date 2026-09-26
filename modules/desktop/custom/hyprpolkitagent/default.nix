{
  config.substrate.modules.desktop.custom.hyprpolkitagent = {
    tags = [ "desktop:custom" ];

    perUser =
      { pkgs, ... }:
      {
        services.hyprpolkitagent = {
          description = "hypr-polkit-agent";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session-pre.target" ];
          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            PartOf = [ "graphical-session.target" ];
          };
          serviceConfig = {
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
