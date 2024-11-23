{
  config,
  ...
}:
{
  options.hdwlinux.hardware.camera = {
    enable = config.lib.hdwlinux.features.mkEnableOption "camera" "camera";
  };
}
