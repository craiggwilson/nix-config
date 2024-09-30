{
  options,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.logind;
in
{
  options.hdwlinux.features.logind = {
    enable = lib.hdwlinux.mkEnableOpt [ "laptop" ] config.hdwlinux.features.tags;
  };

  config.services.logind = lib.mkIf cfg.enable {
    lidSwitchExternalPower = "ignore";
  };
}
