{
  config.substrate.modules.users.craig.onedrive = {
    tags = [ "users:craig:personal" ];

    homeManager =
      { config, ... }:
      {
        hdwlinux.programs.rclone.remotes = {
          onedrive = {
            config = {
              type = "onedrive";
              drive_type = "personal";
            };
            secrets = {
              drive_id = config.hdwlinux.security.secrets.entries.onedriveDriveId.path;
            };
          };
        };

        hdwlinux.security.secrets.entries.onedriveDriveId = {
          reference = "op://Craig/onedrive/drive_id";
          mode = "0600";
        };

        hdwlinux.programs.hdwlinux.subcommands = {
          cloud = {
            onedrive =
              let
                local = "${config.home.homeDirectory}/OneDrive";
                remote = "onedrive:";
                include = ''--include "/{Backups,Documents,Games,MongoDB,Songs}/**"'';
                mkCommand =
                  cmd: src: dst:
                  ''rclone ${cmd} "${src}" "${dst}" ${include} "$@"'';
              in
              {
                check = mkCommand "check" local remote;
                push = mkCommand "sync" local remote;
                pull = mkCommand "sync" remote local;
              };
          };
        };
      };
  };
}
