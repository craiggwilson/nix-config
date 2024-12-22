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
    enable = lib.hdwlinux.mkEnableOption "mission-center" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mission-center ];
  };
}
