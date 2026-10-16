{
  config.substrate.modules.services._1password = {
    provides = [ "security:passwordmanager" ];
    tags = [ "security:passwordmanager" ];

    nixos =
      {
        lib,
        hasCapability,
        ...
      }:
      {
        programs._1password.enable = true;

        programs._1password-gui = lib.mkIf (hasCapability "gui") {
          enable = true;
        };

        security.pam.services."1password".enableGnomeKeyring = hasCapability "gui";
      };

    homeManager =
      {
        hasCapability,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.app.passwordManager = lib.mkIf (hasCapability "gui") (
          lib.mkDefault {
            package = pkgs._1password-gui;
          }
        );
        hdwlinux.app.passwordManager-toggle = lib.mkIf (hasCapability "gui") (
          lib.mkDefault {
            package = pkgs._1password-gui;
            args = [ "--toggle" ];
          }
        );
        hdwlinux.app.passwordManager-lock = lib.mkIf (hasCapability "gui") (
          lib.mkDefault {
            package = pkgs._1password-gui;
            args = [ "--lock" ];
          }
        );

        systemd.user.services."1password" = lib.mkIf (hasCapability "gui") {
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
