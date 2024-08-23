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
  cfg = config.hdwlinux.features.mongodb-tools;
in
{
  options.hdwlinux.features.mongodb-tools = with types; {
    enable = mkEnableOpt [
      "cli"
      "programming"
      "work"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages =
    with pkgs;
    mkIf cfg.enable [
      mongosh
      mongodb-tools
    ];
}
