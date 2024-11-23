{
  lib,
  config,
  ...
}:
{
  options.hdwlinux.hardware.camera = {
    enable = lib.mkOption {
      description = "Whether to enable the camera.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "camera" config.hdwlinux.features.tags);
    };
  };
}
