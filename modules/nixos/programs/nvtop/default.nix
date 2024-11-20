{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programsd.nvtop;
in
{
  options.hdwlinux.programsd.nvtop = {
    enable = lib.hdwlinux.mkEnableTagsOpt "nvtop" [
      "cli"
      "video:nvidia"
    ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nvtopPackages.full ];
  };
}
