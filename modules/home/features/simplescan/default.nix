{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.simplescan;
in
{
  options.hdwlinux.features.simplescan = {
    enable = lib.hdwlinux.mkEnableOpt [ "scanning" ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [ pkgs.simple-scan ];
}
