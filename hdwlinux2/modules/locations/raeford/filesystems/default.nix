{
  config.substrate.modules.locations.raeford.filesystems = {
    tags = [
      "raeford"
      "filesystem:nfs"
    ];

    nixos =
      {
        lib,
        config,
        hasTag,
        ...
      }:
      {
        fileSystems."/mnt/shared" = {
          device = "synology.${config.hdwlinux.networking.domain}:/volume1/shared";
          fsType = "nfs";
          options = [
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=600"
          ];
        };
        fileSystems."/mnt/games" = lib.mkIf (hasTag "gaming") {
          device = "synology.${config.hdwlinux.networking.domain}:/volume2/games";
          fsType = "nfs";
          options = [
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=600"
          ];
        };
      };
  };
}
