{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.ranger;
in
{
  options.hdwlinux.features.ranger = with types; {
    enable = mkBoolOpt false "Whether or not to enable ranger.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    ranger    
  ];
}
