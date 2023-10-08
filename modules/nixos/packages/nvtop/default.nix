{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.nvtop;
in
{
  options.hdwlinux.packages.nvtop = with types; {
    enable = mkBoolOpt false "Whether or not to enable nvtop.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        nvtop
    ];
  };
}
