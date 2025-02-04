{
  options,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.zoom-us;
in
{
  options.hdwlinux.programs.zoom-us = {
    enable = config.lib.hdwlinux.mkEnableOption "zoom-us" false;
    # [
    #   "gui"
    #   "work"
    # ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.zoom-us ];
  };
}
