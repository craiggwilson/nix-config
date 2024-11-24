{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.irqbalance;
in
{
  options.hdwlinux.services.irqbalance = {
    enable = lib.hdwlinux.mkEnableOption "irqbalance" true;
  };

  config = lib.mkIf cfg.enable {
    services.irqbalance.enable = true;
  };
}
