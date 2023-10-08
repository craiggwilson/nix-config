{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.thunderbolt; 
in {
  
  options.hdwlinux.packages.thunderbolt = with types; {
    enable = mkBoolOpt false "Whether or not to enable thunderbolt support.";
  };

  config = mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "thunderbolt" ];

    services.hardware.bolt.enable = true;
  };
}
