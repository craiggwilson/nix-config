{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.hardware.thunderbolt;
in
{
  options.hdwlinux.hardware.thunderbolt = {
    enable = config.lib.hdwlinux.mkEnableOption "thunderbolt" "thunderbolt";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "thunderbolt" ];
    services.hardware.bolt.enable = true;
  };
}
