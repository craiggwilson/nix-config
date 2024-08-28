{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.irqbalance;
in
{
  options.hdwlinux.features.irqbalance = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable irqbalance feature.";
  };

  config = lib.mkIf cfg.enable {
    services.irqbalance.enable = true;
  };
}
