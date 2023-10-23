{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.bc;
in
{
  options.hdwlinux.features.bc = with types; {
    enable = mkBoolOpt false "Whether or not to enable bc.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    bc
  ];
}
