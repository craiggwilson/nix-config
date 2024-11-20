{
  lib,
  config,
  ...
}:
let
  tags = config.hdwlinux.features.tags;
  cfg = config.hdwlinux.services.thunderbolt;
in
{
  options.hdwlinux.services.thunderbolt = {
    enable = lib.hdwlinux.mkEnableTagsOpt "thunderbolt" [ "thunderbolt" ] tags;
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "thunderbolt" ];
    services.hardware.bolt.enable = true;
  };
}
