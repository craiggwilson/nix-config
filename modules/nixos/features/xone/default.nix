{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.xone;
in
{
  options.hdwlinux.features.xone = with types; {
    enable = mkEnableOpt ["gaming"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    hardware.xone.enable = true;
  };
}
