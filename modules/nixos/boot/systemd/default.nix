{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.boot.systemd;
in
{
  options.hdwlinux.boot.systemd = {
    enable = lib.hdwlinux.mkEnableTagsOpt "systemd boot" [
      "boot:systemd"
    ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        systemd-boot = {
          enable = true;
          configurationLimit = 20;
        };
      };

      initrd.systemd.enable = true;
    };
  };
}
