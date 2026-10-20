{
  config.substrate.modules.desktop.shells.custom.hyprpolkitagent = {
    tags = [ "desktop:shells:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        systemd.user.services.hyprpolkitagent = {
          Unit = {
            ConditionEnvironment = [
              "WAYLAND_DISPLAY"
              "HDWLINUX_SHELL=custom"
            ];
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
