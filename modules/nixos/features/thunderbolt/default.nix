{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.thunderbolt;
in
{

  options.hdwlinux.features.thunderbolt = {
    enable = lib.hdwlinux.mkEnableOpt [ "thunderbolt" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "thunderbolt" ];
    services.hardware.bolt.enable = true;
  };
}
