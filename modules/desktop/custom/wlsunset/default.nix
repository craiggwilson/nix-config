{
  config.substrate.modules.desktop.custom.wlsunset = {
    tags = [ "desktop:custom" ];

    perUser =
      { pkgs, ... }:
      {
        services.wlsunset = {
          description = "wlsunset";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          unitConfig.PartOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.wlsunset}/bin/wlsunset -l 32.7942 -L -96.7655";
            Restart = "always";
            RestartSec = 10;
          };
        };
      };
  };
}
