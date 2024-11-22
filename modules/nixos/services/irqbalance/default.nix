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
    enable = lib.mkOption {
      description = "Whether to enable irqbalance, a daemons to distribute hardware interrupts across processors on a multiprocessor system.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.irqbalance.enable = true;
  };
}
