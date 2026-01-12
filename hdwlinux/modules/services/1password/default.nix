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
        hdwlinux.apps.passwordManager = lib.mkIf (hasTag "gui") {
          package = pkgs._1password-gui;
          argGroups = {
            toggle = [ "--toggle" ];
            lock = [ "--lock" ];
            quickaccess = [ "--quick-access" ];
          };
        };

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

