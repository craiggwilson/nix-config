{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.discord;
in
{
  options.hdwlinux.programs.discord = {
    enable = config.lib.hdwlinux.mkEnableOption "discord" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.discord ];
  };
}
