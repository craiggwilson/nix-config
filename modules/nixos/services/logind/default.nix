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
    enable = lib.hdwlinux.mkEnableOption "logind" true;
  };

  config = lib.mkIf cfg.enable {
    services.logind = {
      lidSwitchExternalPower = "ignore";
    };
  };
}
