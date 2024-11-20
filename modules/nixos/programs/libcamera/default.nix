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
    enable = lib.hdwlinux.mkEnableTagsOpt "libcamera" [ "camera" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.libcamera ];
  };
}
