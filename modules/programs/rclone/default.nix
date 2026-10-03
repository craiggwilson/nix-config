{
  config.substrate.modules.programs.rclone = {
    tags = [ "cloud:sync" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.rclone;

        varOf = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);

        # Plaintext config is set by the shell wrapper. Secret values are not
        # passed through env: each secretspec entry is named exactly as the
        # RCLONE_CONFIG_* variable rclone reads, and the secrets contributor
        # exports it into the environment at exec time.
        plaintextEnv =
          lib.mergeAttrsList (
            lib.mapAttrsToList (
              remoteName: remote:
              lib.listToAttrs (
                lib.mapAttrsToList (n: v: {
                  name = "RCLONE_CONFIG_${varOf remoteName}_${varOf n}";
                  value = v;
                }) remote.config
              )
            ) cfg.remotes
          );

        rclonePkg = wrap.package {
          package = wrap.package {
            package = pkgs.rclone;
            env = plaintextEnv;
          };
          secrets.scope = "rclone";
        };

        allEntries = lib.unique (lib.flatten (lib.mapAttrsToList (_: r: r.secrets) cfg.remotes));
      in
      {
        options.hdwlinux.programs.rclone.remotes = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                config = lib.mkOption {
                  description = "Plaintext config options.";
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                };
                secrets = lib.mkOption {
                  description = ''
                    Secretspec entry names holding secret config values. Each
                    name is the RCLONE_CONFIG_<REMOTE>_<KEY> variable rclone
                    reads, exported into the environment at exec time by
                    the secrets contributor.
                  '';
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
              };
            }
          );
          default = { };
          description = "Remote configurations provided to rclone through env overrides.";
        };

        config = lib.mkIf (cfg.remotes != { }) {
          home.packages = [ rclonePkg ];
          secretspec.scopes.rclone.secrets = allEntries;
        };
      };
  };
}
