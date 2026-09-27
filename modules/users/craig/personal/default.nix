{
  config.substrate.modules.users.craig.personal = {
    tags = [ "users:craig:personal" ];

    perUser =
      { config, ... }:
      {
        # rclone remotes + the onedrive drive-id secret stay home-manager-side
        # until the rclone/secrets waves; only the CLI contribution moves.
        hdwlinux.programs.hdwlinux.subcommands = {
          cloud = {
            onedrive =
              let
                local = "${config.homeDirectory}/OneDrive";
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

    homeManager =
      { config, ... }:
      {
        hdwlinux = {
          programs.rclone.remotes = {
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

          security.secrets.entries.onedriveDriveId = {
            reference = "op://Craig/onedrive/drive_id";
            mode = "0600";
          };
        };
      };
  };
}
