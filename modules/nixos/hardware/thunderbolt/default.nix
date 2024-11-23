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
    enable = lib.mkOption {
      description = "Whether to enable thunderbolt.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "thunderbolt" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = [ "thunderbolt" ];
    services.hardware.bolt.enable = true;
  };
}
