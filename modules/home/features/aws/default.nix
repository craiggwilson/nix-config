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
  cfg = config.hdwlinux.features.aws;
in
{
  options.hdwlinux.features.aws = with types; {
    enable = mkEnableOpt [
      "cli"
      "programming"
      "work"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ awscli2 ];
}
