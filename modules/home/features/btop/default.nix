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
  cfg = config.hdwlinux.features.btop;
in
{
  options.hdwlinux.features.btop = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.programs.btop = mkIf cfg.enable { enable = true; };
}
