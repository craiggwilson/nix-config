{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.virtualization.waydroid;
in
{
  options.hdwlinux.features.virtualization.waydroid = {
    enable = lib.hdwlinux.mkEnableOpt [ "virtualization:waydroid" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
  };
}
