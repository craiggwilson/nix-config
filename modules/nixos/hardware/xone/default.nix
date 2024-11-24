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
    enable = config.lib.hdwlinux.mkEnableOption "xone" "gaming";
  };

  config = lib.mkIf cfg.enable {
    hardware.xone.enable = true;
  };
}
