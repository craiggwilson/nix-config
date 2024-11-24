{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.viddy;
in
{
  options.hdwlinux.programs.viddy = {
    enable = lib.hdwlinux.mkEnableOption "viddy" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.viddy ];
  };
}
