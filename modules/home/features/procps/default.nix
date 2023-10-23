{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.procps;
in
{
  options.hdwlinux.features.procps = with types; {
    enable = mkBoolOpt false "Whether or not to enable procps.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    procps
  ];
}
