{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.musescore;
in
{
  options.hdwlinux.features.musescore = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    musescore
  ];
}
