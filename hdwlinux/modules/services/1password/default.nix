{
  config.substrate.modules.services._1password = {
    tags = [ "gui" "security:passwordmanager" ];

    homeManager =
      { pkgs, ... }:
      {
        systemd.user.services."1password" = {
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

