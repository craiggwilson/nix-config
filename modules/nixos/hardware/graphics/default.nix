{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.graphics;
in
{
  options.hdwlinux.hardware.graphics = {
    enable = lib.hdwlinux.mkEnableOpt [ "video" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
