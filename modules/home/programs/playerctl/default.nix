{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.playerctl;
in
{
  options.hdwlinux.programs.playerctl = {
    enable = config.lib.hdwlinux.mkEnableOption "playerctl" "audio";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.playerctl ];
  };
}
