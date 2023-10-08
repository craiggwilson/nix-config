{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.pciutils;
in
{
  options.hdwlinux.packages.pciutils = with types; {
    enable = mkBoolOpt false "Whether or not to enable pciutils.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        pciutils
    ];
  };
}
