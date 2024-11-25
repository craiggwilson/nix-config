{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.gimp;
in
{
  options.hdwlinux.programs.gimp = {
    enable = config.lib.hdwlinux.mkEnableOption "gimp" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gimp ];
  };
}
