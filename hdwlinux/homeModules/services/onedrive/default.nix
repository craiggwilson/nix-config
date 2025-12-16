{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.onedrive;
in
{
  options.hdwlinux.services.onedrive = {
    enable = config.lib.hdwlinux.mkEnableOption "onedrive" "personal";
    syncList = lib.mkOption {
      description = "List of folders to sync.";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.onedrive ];

    xdg.configFile."onedrive/sync_list".text = lib.strings.concatLines cfg.syncList;

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
