{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.musescore;
in
{
  options.hdwlinux.programs.musescore = {
    enable = config.lib.hdwlinux.mkEnableAllOption "musescore" [
      "gui"
      "personal"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.musescore ];
  };
}
