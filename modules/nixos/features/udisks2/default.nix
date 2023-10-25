{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.udisks2;
in
{
  options.hdwlinux.features.udisks2 = with types; {
    enable = mkBoolOpt false "Whether or not to enable the udisks2 service.";
  };

  config = mkIf cfg.enable {
    services.udisks2.enable = true;
  };
}
