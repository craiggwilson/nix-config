{
  config.substrate.modules.services._1password = {
    tags = [ "security:passwordmanager" ];

    nixos =
      {
        lib,
        hasTag,
        ...
      }:
      {
        programs._1password.enable = true;

        programs._1password-gui = lib.mkIf (hasTag "gui") {
          enable = true;
        };

        security.pam.services."1password".enableGnomeKeyring = hasTag "gui";
      };

    perUser =
      {
        hasTag,
        lib,
        pkgs,
        ...
      }:
      lib.mkIf (hasTag "gui") {
        hdwlinux.app.passwordManager = lib.mkDefault {
          package = pkgs._1password-gui;
        };
        hdwlinux.app.passwordManager-toggle = lib.mkDefault {
          package = pkgs._1password-gui;
          args = [ "--toggle" ];
        };
        hdwlinux.app.passwordManager-lock = lib.mkDefault {
          package = pkgs._1password-gui;
          args = [ "--lock" ];
        };

        services."1password" = {
          description = "Password manager daemon";
          wantedBy = [ "graphical-session-pre.target" ];
          after = [ "graphical-session-pre.target" ];
          unitConfig.PartOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
            Restart = "always";
            RestartSec = "10";
          };
        };
      };
  };
}
