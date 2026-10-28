{
  config.substrate.modules.services.cifs = {
    tags = [ "capability:filesystem:cifs" ];

    generic =
      { lib, ... }:
      let
        cifsMountType = lib.types.submodule {
          options = {
            auto = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to automount this share when accessed.";
            };
            credentialsFile = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Path to a mount.cifs credentials file.";
            };
            group = lib.mkOption {
              type = lib.types.str;
              description = "Local group that owns the mounted files.";
            };
            local = lib.mkOption {
              type = lib.types.str;
              description = "Local mount path.";
            };
            remote = lib.mkOption {
              type = lib.types.str;
              description = "Full SMB path (e.g., '//server/share').";
            };
            owner = lib.mkOption {
              type = lib.types.str;
              description = "Local user that owns the mounted files.";
            };
            username = lib.mkOption {
              type = lib.types.str;
              description = "SMB username used for this mount.";
            };
          };
        };
      in
      {
        options.hdwlinux.filesystems.cifs.mounts = lib.mkOption {
          description = "List of SMB mounts to configure.";
          type = lib.types.listOf cifsMountType;
          default = [ ];
        };
      };

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cifsMounts = config.hdwlinux.filesystems.cifs.mounts or [ ];
        mountOptions =
          m:
          [
            (if m.credentialsFile == null then "username=${m.username}" else "credentials=${m.credentialsFile}")
            "vers=3.1.1"
            "uid=${toString config.users.users.${m.owner}.uid}"
            "gid=${toString config.users.groups.${m.group}.gid}"
            "file_mode=0600"
            "dir_mode=0700"
          ]
          ++ lib.optionals m.auto [
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=600"
          ];
      in
      {
        environment.systemPackages = [ pkgs.cifs-utils ];
        fileSystems = lib.listToAttrs (
          map (m: {
            name = m.local;
            value = {
              device = m.remote;
              fsType = "cifs";
              options = mountOptions m;
            };
          }) cifsMounts
        );
      };
  };
}
