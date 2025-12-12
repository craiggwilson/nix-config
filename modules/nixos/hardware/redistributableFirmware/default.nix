{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.hardware.redistributableFirmware;
in
{

  options.hdwlinux.hardware.redistributableFirmware = {
    enable = lib.hdwlinux.mkEnableOption "redistributableFirmware" true;
  };

  config = lib.mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
  };
}
