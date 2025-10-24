{
  config,
  ...
}:
{
  options.hdwlinux.hardware.camera = {
    enable = config.lib.hdwlinux.mkEnableOption "camera" "camera";
  };
}
