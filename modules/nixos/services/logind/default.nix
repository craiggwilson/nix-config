{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.logind;
in
{
  options.hdwlinux.services.logind = {
    enable = lib.hdwlinux.mkEnableOpt [ "laptop" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.logind = {
      lidSwitchExternalPower = "ignore";
    };
  };
}
