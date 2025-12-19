{ lib, ... }:
let
  nfsMountType = lib.types.submodule {
    options = {
      local = lib.mkOption {
        type = lib.types.str;
        description = "Local mount point path.";
      };
      remote = lib.mkOption {
        type = lib.types.str;
        description = "Remote NFS path (e.g., 'server:/volume/share').";
      };
      auto = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to automount this filesystem.";
      };
    };
  };
in
{
  config.substrate.types.nfsMount = nfsMountType;

  config.substrate.modules.filesystems.nfs = {
    tags = [ "filesystem:nfs" ];

    nixos =
      { lib, config, ... }:
      let
        nfsMounts = config.hdwlinux.filesystems.nfs.mounts or [ ];
      in
      {
        options.hdwlinux.filesystems.nfs.mounts = lib.mkOption {
          description = "List of NFS mounts to configure.";
          type = lib.types.listOf nfsMountType;
          default = [ ];
        };

        config = {
          boot.supportedFilesystems = [ "nfs" ];
          services.rpcbind.enable = true;

          systemd.mounts = builtins.map (m: {
            type = "nfs";
            mountConfig = {
              Options = "noatime";
            };
            what = m.remote;
            where = m.local;
          }) nfsMounts;

          systemd.automounts = builtins.map (m: {
            wantedBy = [ "multi-user.target" ];
            automountConfig = {
              TimeoutIdleSec = "600";
            };
            where = m.local;
          }) (builtins.filter (m: m.auto == true) nfsMounts);
        };
      };
  };
}

