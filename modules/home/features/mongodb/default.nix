{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.mongodb;
in
{
  options.hdwlinux.features.mongodb = {
    enable = lib.hdwlinux.mkBoolOpt false "Enable MongoDB";
  };

  config.home.packages = lib.mkIf cfg.enable [ pkgs.mongodb-5_0 ];
}
