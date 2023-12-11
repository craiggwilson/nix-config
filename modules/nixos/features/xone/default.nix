{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.xone;
in
{
  options.hdwlinux.features.xone = with types; {
    enable = mkBoolOpt false "Whether or not to enable the xbox one hardware.";
  };

  config = mkIf cfg.enable {
    hardware.xone.enable = true;
  };
}
