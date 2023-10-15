{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.grimblast;
in
{
  options.hdwlinux.packages.grimblast = with types; {
    enable = mkBoolOpt false "Whether or not to enable grimblast.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        grimblast
    ];
  };
}
