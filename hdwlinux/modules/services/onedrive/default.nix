{ lib, ... }:
{
  config.substrate.modules.services.onedrive = {
    tags = [ "users:craig:personal" ];

    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      {
        config = {
          home.packages = [ pkgs.onedrive ];

          xdg.configFile."onedrive/sync_list".text = lib.strings.concatLines [
            "/Backups"
            "/Documents"
            "/Games"
            "/MongoDB"
            "/Songs"
          ];

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
      };
  };
}
