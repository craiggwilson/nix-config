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
    enable = config.lib.hdwlinux.mkEnableOption "waydroid" "virtualization:waydroid";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
  };
}
