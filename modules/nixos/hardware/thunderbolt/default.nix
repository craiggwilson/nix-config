{
  lib,
  config,
  ...
}:
let
  tags = config.hdwlinux.features.tags;
  cfg = config.hdwlinux.hardware.thunderbolt;
in
{
  options.hdwlinux.hardware.thunderbolt = {
    enable = lib.hdwlinux.mkEnableTagsOpt "thunderbolt" [ "thunderbolt" ] tags;
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "thunderbolt" ];
    services.hardware.bolt.enable = true;
  };
}
