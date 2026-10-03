{
  config.substrate.modules.users.craig.personal = {
    tags = [ "users:craig:personal" ];

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
              secrets = [ "RCLONE_CONFIG_ONEDRIVE_DRIVE_ID" ];
            };
          };

          programs.hdwlinux.subcommands.cloud = {
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

        secretspec.entries.RCLONE_CONFIG_ONEDRIVE_DRIVE_ID = {
          description = "OneDrive drive id rclone needs to address the remote.";
          ref = {
            vault = "Craig";
            item = "onedrive";
            field = "drive_id";
          };
        };
      };
  };
}
