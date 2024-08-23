{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.viddy;
in
{
  options.hdwlinux.features.viddy = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ viddy ];
}
