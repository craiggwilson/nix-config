{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.evergreen;
in
{
  options.hdwlinux.packages.evergreen = with types; {
    enable = mkBoolOpt false "Whether or not to enable evergreen.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        hdwlinux.evergreen
    ];
  };
}

