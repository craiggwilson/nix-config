{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.obsidian;
in
{
  options.hdwlinux.programs.obsidian = {
    enable = config.lib.hdwlinux.mkEnableOption "obsidian" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.obsidian ];
  };
}
