{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.azure;
in
{
  options.hdwlinux.features.azure = with types; {
    enable = mkBoolOpt false "Whether or not to enable azure.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    azure-cli
  ];
}
