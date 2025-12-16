{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.filesystems.nfs;
in
{
  options.hdwlinux.filesystems.nfs = {
    enable = config.lib.hdwlinux.mkEnableOption "nfs" "filesystem:nfs";
    mounts = lib.mkOption {
      description = "Options to the set of mounts to make available.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            local = lib.mkOption { type = lib.types.str; };
            remote = lib.mkOption { type = lib.types.str; };
            auto = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "nfs" ];
    services.rpcbind.enable = true;
    systemd.mounts = builtins.map (m: {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = m.remote;
      where = m.local;
    }) cfg.mounts;

    systemd.automounts = builtins.map (m: {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = m.local;
    }) (builtins.filter (m: m.auto == true) cfg.mounts);
  };
}
