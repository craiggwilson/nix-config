{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.xone;
in
{
  options.hdwlinux.hardware.xone = {
    enable = lib.hdwlinux.mkEnableTagsOpt "xone" [ "gaming" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    hardware.xone.enable = true;
  };
}
