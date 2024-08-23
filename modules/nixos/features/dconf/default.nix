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
  cfg = config.hdwlinux.features.dconf;
in
{
  options.hdwlinux.features.dconf = with types; {
    enable = mkEnableOpt [ "service" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable { programs.dconf.enable = true; };
}
