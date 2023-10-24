{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.mongodb-tools;
in
{
  options.hdwlinux.features.mongodb-tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable mongodb-tools.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    mongosh
    mongodb-tools
  ];
}
