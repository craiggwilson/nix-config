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
  cfg = config.hdwlinux.features.jq;
in
{
  options.hdwlinux.features.jq = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.programs.jq = mkIf cfg.enable { enable = true; };
}
