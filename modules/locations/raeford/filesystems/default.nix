{
  config.substrate.modules.locations.raeford.filesystems = {
    tags = [
      "location:raeford"
      "capability:filesystem:nfs"
    ];

    nixos =
      {
        lib,
        config,
        hasTag,
        ...
      }:
      {
        fileSystems."/mnt/games" = lib.mkIf (hasTag "profile:gaming") {
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
