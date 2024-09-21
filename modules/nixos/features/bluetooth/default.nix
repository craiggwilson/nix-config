{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.bluetooth;
in
{
  options.hdwlinux.features.bluetooth = {
    enable = lib.hdwlinux.mkEnableOpt [ "bluetooth" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
