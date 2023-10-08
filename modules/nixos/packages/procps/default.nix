{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.procps;
in
{
  options.hdwlinux.packages.procps = with types; {
    enable = mkBoolOpt false "Whether or not to enable procps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        procps
    ];
  };
}
