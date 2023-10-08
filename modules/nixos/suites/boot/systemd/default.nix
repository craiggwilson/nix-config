{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.boot.systemd;
in {
  
  options.hdwlinux.suites.boot.systemd = with types; {
    enable = mkBoolOpt false "Whether or not to enable systemd booting.";
    mountPoint = mkStrOpt "/boot" "The efi system mount point.";
    configurationLimit = mkOpt int 20 "The number of boot entries.";
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = mkAliasDefinitions options.hdwlinux.suites.boot.systemd.mountPoint;
        };

        systemd-boot = {
          enable = true;
          configurationLimit = mkAliasDefinitions options.hdwlinux.suites.boot.systemd.configurationLimit;
        };
      };
    };
  };
}
