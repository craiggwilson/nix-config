{
  lib,
  config,
  ...
}:
{
  options.hdwlinux.hardware.camera = {
    enable = lib.hdwlinux.mkEnableTagsOpt "camera" [ "camera" ] config.hdwlinux.features.tags;
  };
}
