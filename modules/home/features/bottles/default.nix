{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.bottles;
in
{
  options.hdwlinux.features.bottles = with types; {
    enable = mkBoolOpt false "Whether or not to enable bottles.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    bottles
  ];
}

