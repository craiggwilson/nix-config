{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.structurizr-cli;
in
{
  options.hdwlinux.features.structurizr-cli = with types; {
    enable = mkBoolOpt false "Whether or not to enable structurizr-cli.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    hdwlinux.structurizr-cli
  ];
}

