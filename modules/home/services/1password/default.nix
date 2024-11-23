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
    enable = lib.mkOption {
      description = "Whether to enable the 1password service.";
      type = lib.types.bool;
      default = (
        lib.hdwlinux.elemsAll [
          "security:passwordmanager"
          "gui"
        ] config.hdwlinux.features.tags
      );
    };
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
