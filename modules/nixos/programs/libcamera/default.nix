{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.libcamera;
in
{
  options.hdwlinux.programs.libcamera = {
    enable = lib.hdwlinux.mkEnableOption "libcamera" config.hdwlinux.hardware.camera.enable;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.libcamera ];
  };
}
