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
    enable = lib.mkOption {
      description = "Whether to enable usbutils.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.usbutils ];
  };
}
