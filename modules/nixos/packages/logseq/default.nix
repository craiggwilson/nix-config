{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.logseq;
in
{
  options.hdwlinux.packages.logseq = with types; {
    enable = mkBoolOpt false "Whether or not to enable logseq.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        logseq
    ];
  };
}
