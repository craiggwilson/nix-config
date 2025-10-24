{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.ffmpeg;
in
{
  options.hdwlinux.programs.ffmpeg = {
    enable = lib.hdwlinux.mkEnableOption "ffmpeg" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ffmpeg ];
  };
}
