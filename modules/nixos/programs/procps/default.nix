{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.procps;
in
{
  options.hdwlinux.programs.procps = {
    enable = lib.mkOption {
      description = "Whether to enable procps.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.procps ];
  };
}
