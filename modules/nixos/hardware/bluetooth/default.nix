{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.hardware.bluetooth;
in
{
  options.hdwlinux.hardware.bluetooth = {
    enable = config.lib.hdwlinux.features.mkEnableOption "bluetooth" "bluetooth";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
