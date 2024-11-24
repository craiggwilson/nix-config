{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.spotify;
in
{
  options.hdwlinux.programs.spotify = {
    enable = config.lib.hdwlinux.mkEnableOption "spotify" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotify ];
  };
}
