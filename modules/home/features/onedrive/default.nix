{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.onedrive;
in
{
  options.hdwlinux.features.onedrive = with types; {
    enable = mkEnableOpt [ "personal" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ onedrive ];

    xdg.configFile."onedrive/sync_list".text = ''
      /Backups
      /Documents
      /Games
      /MongoDB
      /Songs
    '';

    systemd.user.services.onedrive = {
      Unit = {
        Description = "OneDrive Free Client";
        Documentation = [ "https://github.com/abraunegg/onedrive" ];
        After = "network-online.target";
        Wants = "network-online.target";
      };
      Service = {
        ProtectSystem = "full";
        ProtectHostname = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor";
        Restart = "on-failure";
        RestartSec = 3;
        RestartPreventExitStatus = 3;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
