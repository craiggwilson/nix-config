{
  config.substrate.modules.programs.rclone = {
    tags = [ "cloud:sync" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.rclone;
        remoteNames = lib.attrNames cfg.remotes;
        remotesListStr = lib.concatStringsSep ", " remoteNames;

        syncAllScript = ''
          echo "Syncing all remotes: ${remotesListStr}"
          ${lib.concatMapStringsSep "\n" (name: ''
            echo "Syncing remote: ${name}"
            rclone sync "${name}:" --progress
          '') remoteNames}
          echo "All remotes synced."
        '';
      in
      {
        options.hdwlinux.programs.rclone = {
          remotes = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = { };
            description = "Remote configurations to pass through to programs.rclone.remotes. Other modules can contribute remote configurations here.";
          };
        };

        config = {
          programs.rclone = {
            enable = true;
            remotes = cfg.remotes;
          };

          hdwlinux.programs.hdwlinux = {
            runtimeInputs = [ pkgs.rclone ];
            subcommands = {
              cloud = {
                sync = syncAllScript;
                "*" = "rclone listremotes --long";
              };
            };
          };
        };
      };
  };
}
