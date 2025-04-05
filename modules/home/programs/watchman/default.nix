{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.watchman;
in
{
  options.hdwlinux.programs.watchman = {
    enable = lib.hdwlinux.mkEnableOption "watchman" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.watchman ];
  };
}
