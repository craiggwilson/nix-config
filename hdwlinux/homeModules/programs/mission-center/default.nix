{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.mission-center;
in
{
  options.hdwlinux.programs.mission-center = {
    enable = config.lib.hdwlinux.mkEnableOption "mission-center" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mission-center ];
  };
}
