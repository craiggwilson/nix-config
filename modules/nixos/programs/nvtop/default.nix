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
    enable = lib.mkOption {
      description = "Whether to enable nvtop.";
      type = lib.types.bool;
      default = config.hdwlinux.hardware.nvidia.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nvtopPackages.full ];
  };
}
