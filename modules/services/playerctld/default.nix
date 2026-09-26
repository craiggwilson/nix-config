{
  config.substrate.modules.services.playerctld = {
    tags = [ "gui" "audio" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.playerctl ];

        services.playerctld = {
          description = "playerctld";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          unitConfig.PartOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.playerctl}/bin/playerctld";
            Restart = "on-failure";
          };
        };
      };
  };
}
