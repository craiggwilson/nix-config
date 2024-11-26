{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.calibre;
in
{
  options.hdwlinux.programs.calibre = {
    enable = config.lib.hdwlinux.mkEnableOption "calibre" [
      "gui"
      "personal"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.calibre ];
  };
}
