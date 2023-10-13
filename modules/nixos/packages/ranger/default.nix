{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.ranger;
in
{
  options.hdwlinux.packages.ranger = with types; {
    enable = mkBoolOpt false "Whether or not to enable ranger.";
  };

  config.hdwlinux.home.packages = with pkgs; mkIf cfg.enable [
    ranger    
  ];
}
