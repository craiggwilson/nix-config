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
  cfg = config.hdwlinux.features.bat;
in
{
  options.hdwlinux.features.bat = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.programs.bat = mkIf cfg.enable { enable = true; };
}
