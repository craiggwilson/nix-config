{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.redistributableFirmware; 
in {
  
  options.hdwlinux.features.redistributableFirmware = with types; {
    enable = mkEnableOpt ["redistributableFirmware"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
  };
}