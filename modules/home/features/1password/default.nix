{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
let
  cfg = config.hdwlinux.features._1password;
in
{

  options.hdwlinux.features._1password = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
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
