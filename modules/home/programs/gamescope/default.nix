{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.gamescope;
in
{
  options.hdwlinux.programs.gamescope = {
    enable = config.lib.hdwlinux.mkEnableAllOption "gamescope" [
      "gui"
      "gaming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gamescope ];
  };
}
