{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.logseq;
in
{
  options.hdwlinux.features.logseq = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ 
        obsidian
    ];
  };
}
