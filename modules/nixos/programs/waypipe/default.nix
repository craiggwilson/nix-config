{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.waypipe;
in
{
  options.hdwlinux.programs.waypipe = {
    enable = lib.mkOption {
      description = "Whether to enable waypipe.";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.waypipe
      pkgs.xorg.xauth
    ];
  };
}
