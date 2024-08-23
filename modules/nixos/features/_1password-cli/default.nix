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
  cfg = config.hdwlinux.features._1password-cli;
in
{
  options.hdwlinux.features._1password-cli = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.programs._1password.enable = mkIf cfg.enable true;
}
