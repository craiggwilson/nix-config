{
  config.substrate.modules.desktop.custom.udiskie = {
    tags = [ "desktop:custom" ];

    perUser =
      { pkgs, ... }:
      {
        # Mirrors home-manager's services.udiskie (tray = "auto"):
        # config.yml program_options + unit wired to tray.target.
        files.".config/udiskie/config.yml".text = ''
          program_options:
            automount: true
            notify: true
            tray: auto
        '';

        services.udiskie = {
          description = "udiskie mount daemon";
          wantedBy = [ "graphical-session.target" ];
          after = [
            "graphical-session.target"
            "tray.target"
          ];
          unitConfig = {
            Requires = [ "tray.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          serviceConfig.ExecStart = "${pkgs.udiskie}/bin/udiskie";
        };
      };
  };
}
