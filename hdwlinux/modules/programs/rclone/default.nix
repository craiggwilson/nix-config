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

        mapRemote =
          remoteName: remote:
          let
            plain = lib.concatMapAttrsStringSep " " (
              name: value:
              let
                remoteName' = lib.toUpper remoteName;
                name' = lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name);
                value' = lib.strings.escapeShellArg value;
              in
              ''RCLONE_CONFIG_${remoteName'}_${name'}="${value'}"''
            ) remote.config;
            secrets = lib.concatMapAttrsStringSep " " (
              name: value:
              let
                remoteName' = lib.toUpper remoteName;
                name' = lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name);
                value' = "$(cat ${value})";
              in
              "RCLONE_CONFIG_${remoteName'}_${name'}=${value'}"
            ) remote.secrets;
          in
          "${plain} ${secrets}";

        envList = lib.concatMapAttrsStringSep " " mapRemote cfg.remotes;
        rclonePkg = pkgs.writeShellApplication {
          name = "rclone";
          runtimeInputs = [
            pkgs.rclone
          ];
          text = ''
            ${envList} rclone "$@" 
          '';
        };
      in
      {
        options.hdwlinux.programs.rclone = {
          remotes = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  config = lib.mkOption {
                    description = "Plaintext config options.";
                    type = lib.types.attrsOf lib.types.str;
                    default = { };
                  };
                  secrets = lib.mkOption {
                    description = "Secret config options provided as runtime paths.";
                    type = lib.types.attrsOf lib.types.str;
                    default = { };
                  };
                };
              }
            );
            default = { };
            description = "Remote configurations to provide to rsync.";
          };
        };

        config = {
          home.packages = [ rclonePkg ];
        };
      };
  };
}
