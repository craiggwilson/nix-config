{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.thunderbolt; 
in {
  
  options.hdwlinux.features.thunderbolt = with types; {
    enable = mkEnableOpt ["thunderbolt"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    boot.initrd.availableKernelModules = ["thunderbolt"];

    services.hardware.bolt.enable = true;
  };
}
