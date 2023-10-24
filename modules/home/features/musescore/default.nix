{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.musescore;
in
{
  options.hdwlinux.features.musescore = with types; {
    enable = mkBoolOpt false "Whether or not to enable musescore.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    musescore
  ];
}
