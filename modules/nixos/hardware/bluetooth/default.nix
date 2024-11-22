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
    enable = lib.hdwlinux.mkEnableTagsOpt "blueman" [ "bluetooth" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
