{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.usbutils;
in
{
  options.hdwlinux.features.usbutils = {
    enable = lib.hdwlinux.mkEnableOption "usbutils" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.usbutils ];
  };
}
