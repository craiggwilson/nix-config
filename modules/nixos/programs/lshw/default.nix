{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.lshw;
in
{
  options.hdwlinux.programs.lshw = {
    enable = lib.mkOption {
      description = "Whether to enable lshw.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lshw ];
  };
}
