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
    enable = lib.hdwlinux.mkEnableOpt [ "work" ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [ pkgs.mongodb-5_0 ];
}
