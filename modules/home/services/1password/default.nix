{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services._1password;
in
{

  options.hdwlinux.services._1password = {
    enable = config.lib.hdwlinux.mkEnableOption "1password" [
      "gui"
      "security:passwordmanager"
    ];
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services."1password" = {
      Unit = {
        Description = "Password manager daemon";
        Documentation = [
          "https://www.1password.com"
        ];
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
}
