{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.lshw;
in
{
  options.hdwlinux.packages.lshw = with types; {
    enable = mkBoolOpt false "Whether or not to enable lshw.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        lshw
    ];
  };
}
