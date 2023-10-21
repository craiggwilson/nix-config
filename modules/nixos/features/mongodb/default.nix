{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.mongodb;
in
{
  options.hdwlinux.features.mongodb = with types; {
    enable = mkBoolOpt false "Whether or not to enable mongodb.";
  };

  config.hdwlinux.home = mkIf cfg.enable {
    packages = with pkgs; [ 
      mongodb-5_0
      mongosh
      mongodb-tools
    ];
  };
}
