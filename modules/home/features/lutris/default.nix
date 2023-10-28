{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.lutris;
in
{
  options.hdwlinux.features.lutris = with types; {
    enable = mkBoolOpt false "Whether or not to enable lutris.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    lutris
  ];
}
