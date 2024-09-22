{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.video;
in
{
  options.hdwlinux.features.video = {
    enable = lib.hdwlinux.mkEnableOpt [ "video" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
