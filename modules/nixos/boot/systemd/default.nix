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
    enable = config.lib.hdwlinux.mkEnableOption "systemd" "boot:systemd";
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
