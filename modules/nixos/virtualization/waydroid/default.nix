{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.virtualization.waydroid;
in
{
  options.hdwlinux.virtualization.waydroid = {
    enable = lib.hdwlinux.mkEnableOpt [ "virtualization:waydroid" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
  };
}
