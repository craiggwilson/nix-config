{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.usbutils;
in
{
  options.hdwlinux.programs.usbutils = {
    enable = lib.hdwlinux.mkEnableOption "usbutils" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.usbutils ];
  };
}
