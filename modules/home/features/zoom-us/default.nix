{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.zoom-us;
in
{
  options.hdwlinux.features.zoom-us = with types; {
    enable = mkBoolOpt false "Whether or not to enable zoom-us.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    zoom-us
  ];
}