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
    enable = lib.mkOption {
      description = "Whether to enable systemd boot.";
      type = lib.types.bool;
      default = (builtins.elem "boot:systemd" config.hdwlinux.features.tags);
    };
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
