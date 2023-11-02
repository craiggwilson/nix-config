{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.structurizr-lite;
in
{
  options.hdwlinux.features.structurizr-lite = with types; {
    enable = mkBoolOpt false "Whether or not to enable structurizr-lite.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    hdwlinux.structurizr-lite
  ];
}

