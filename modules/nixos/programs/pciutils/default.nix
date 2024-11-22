{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.pciutils;
in
{
  options.hdwlinux.programs.pciutils = {
    enable = lib.mkOption {
      description = "Whether to enable pciutils.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pciutils ];
  };
}
