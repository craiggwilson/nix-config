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
    enable = lib.mkOption {
      description = "Whether to enable libcamera.";
      type = lib.types.bool;
      default = config.hdwlinux.hardware.camera.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.libcamera ];
  };
}
