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
    enable = lib.mkOption {
      description = "Whether to enable logind.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.logind = {
      lidSwitchExternalPower = "ignore";
    };
  };
}
