{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.boot;
in {
  
  options.hdwlinux.packages.boot = {
    enable = mkBoolOpt false "Whether or not to enable systemd booting.";
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