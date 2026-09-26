{
  config.substrate.modules.desktop.noctalia.udiskie = {
    tags = [ "desktop:noctalia" ];

    perUser =
      { pkgs, ... }:
      {
        # Mirrors home-manager's services.udiskie (tray = "never"): no
        # tray.target dependency, tray disabled in program_options.
        files.".config/udiskie/config.yml".text = ''
          program_options:
            automount: true
            notify: true
            tray: false
        '';

        services.udiskie = {
          description = "udiskie mount daemon";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          unitConfig.PartOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.udiskie}/bin/udiskie";
        };
      };
  };
}
