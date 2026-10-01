{

  config.substrate.modules.desktop.custom.syshud = {
    tags = [ "desktop:custom" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {

        xdg.configFile."sys64/hud/style.css".source = ./style.css;

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
            ExecStart = "${pkgs.syshud}/bin/syshud -o horizontal -p topmiddle";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
      };
  };
}
