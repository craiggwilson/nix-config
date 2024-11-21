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
    enable = lib.hdwlinux.mkEnableTagsOpt "usbutils" [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.usbutils ];
  };
}
