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
    enable = lib.mkOption {
      description = "Whether to enable bluetooth.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "bluetooth" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
