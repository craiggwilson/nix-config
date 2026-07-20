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

    homeManager =
      {
        hasTag,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.app.passwordManager = lib.mkIf (hasTag "gui") (lib.mkDefault {
          package = pkgs._1password-gui;
        });
        hdwlinux.app.passwordManager-toggle = lib.mkIf (hasTag "gui") (lib.mkDefault {
          package = pkgs._1password-gui;
          args = [ "--toggle" ];
        });
        hdwlinux.app.passwordManager-lock = lib.mkIf (hasTag "gui") (lib.mkDefault {
          package = pkgs._1password-gui;
          args = [ "--lock" ];
        });

        systemd.user.services."1password" = lib.mkIf (hasTag "gui") {
          Unit = {
            Description = "Password manager daemon";
            Documentation = [ "https://www.1password.com" ];
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session-pre.target" ];
          };
          Service = {
            ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
            Restart = "always";
            RestartSec = "10";
          };
        };
      };
  };
}

