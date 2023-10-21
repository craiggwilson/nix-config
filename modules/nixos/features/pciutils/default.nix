{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.pciutils;
in
{
  options.hdwlinux.features.pciutils = with types; {
    enable = mkBoolOpt false "Whether or not to enable pciutils.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        pciutils
    ];
  };
}
