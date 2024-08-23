{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.boot.systemd;
in
{

  options.hdwlinux.features.boot.systemd = {
    enable = mkEnableOpt [ "boot:systemd" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
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
    };
  };
}
