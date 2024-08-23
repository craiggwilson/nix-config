{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.nfs;
in
{
  options.hdwlinux.features.nfs = with types; {
    enable = mkEnableOpt [ "filesystem:nfs" ] config.hdwlinux.features.tags;
    mounts = mkOption {
      description = "Options to the set of mounts to make available.";
      type = listOf (submodule {
        options = {
          local = mkOption { type = str; };
          remote = mkOption { type = str; };
          auto = mkOption {
            type = bool;
            default = false;
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
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
