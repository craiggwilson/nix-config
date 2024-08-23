{
  options,
  config,
  pkgs,
  lib,
  host ? "",
  format ? "",
  inputs ? { },
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.fingerprint;
in
{
  options.hdwlinux.features.fingerprint = with types; {
    enable = mkEnableOpt [ "fingerprint" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable { services.fprintd.enable = true; };
}
