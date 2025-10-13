{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.filesystems;
  domain = config.hdwlinux.networking.domain or "raeford.wilsonfamilyhq.com";
in
{
  options.hdwlinux.raeford.filesystems = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office filesystem mounts" "raeford";
  };

  config = lib.mkIf cfg.enable {
    # Enable NFS and add raeford office filesystem mounts
    hdwlinux.filesystems.nfs.enable = lib.mkDefault true;
    hdwlinux.filesystems.nfs.mounts = [
      # Shared office files
      {
        local = "/mnt/shared";
        remote = "synology.${domain}:/volume1/shared";
        auto = true;
      }
    ]
    ++ (lib.optionals (lib.hdwlinux.matchTag "gaming" config.hdwlinux.tags) [
      # Gaming files for systems with gaming tag
      {
        local = "/mnt/games";
        remote = "synology.${domain}:/volume2/games";
        auto = true;
      }
    ]);
  };
}
