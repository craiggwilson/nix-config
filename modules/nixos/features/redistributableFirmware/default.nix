{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.redistributableFirmware; 
in {
  
  options.hdwlinux.features.redistributableFirmware = with types; {
    enable = mkBoolOpt false "Whether or not to enable redistributable firmware support.";
  };

  config = mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
  };
}