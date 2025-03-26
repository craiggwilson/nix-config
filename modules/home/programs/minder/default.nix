{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.minder;
in
{
  options.hdwlinux.programs.minder = {
    enable = lib.hdwlinux.mkEnableOption "minder" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.minder
    ];
  };
}
