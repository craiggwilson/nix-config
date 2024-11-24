{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.vlc;
in
{
  options.hdwlinux.programs.vlc = {
    enable = config.lib.hdwlinux.mkEnableOption "vlc" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.vlc ];
  };
}
