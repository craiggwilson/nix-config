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
  cfg = config.hdwlinux.features.osquery;
in
{
  options.hdwlinux.features.osquery = with types; {
    enable = mkEnableOpt [ "work" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable { services.osquery.enable = true; };
}
