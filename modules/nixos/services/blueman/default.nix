{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.blueman;
in
{
  options.hdwlinux.services.blueman = {
    enable = lib.hdwlinux.mkEnableTagsOpt "blueman" [ "bluetooth" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
