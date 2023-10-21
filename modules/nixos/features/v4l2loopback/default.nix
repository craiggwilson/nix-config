{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.v4l2loopback; 
in {
  
  options.hdwlinux.features.v4l2loopback = with types; {
    enable = mkBoolOpt false "Whether or not to enable v4l2loopback support.";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = [ "v4l2loopback" ];
      extraModulePackages = with config.boot.kernelPackages; [ 
        v4l2loopback.out 
      ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
      '';
    };
  };
}
