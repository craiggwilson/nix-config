{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.hardware.redistributableFirmware;
in
{

  options.hdwlinux.hardware.redistributableFirmware = {
    enable = lib.mkOption {
      description = "Whether to enable redistributableFirmware.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
  };
}
