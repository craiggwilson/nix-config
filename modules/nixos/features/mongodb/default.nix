{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.mongodb;
in
{
  options.hdwlinux.features.mongodb = with types; {
    enable = mkBoolOpt false "Whether or not to enable mongodb.";
  };

  config.environment.systemPackages = with pkgs; mkIf cfg.enable [
    mongodb-5_0
  ];
}
