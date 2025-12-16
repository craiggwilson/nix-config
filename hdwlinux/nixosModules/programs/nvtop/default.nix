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
    enable = lib.hdwlinux.mkEnableOption "nvtop" config.hdwlinux.hardware.graphics.nvidia.enable;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nvtopPackages.full ];
  };
}
