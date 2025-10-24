{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.simplescan;
in
{
  options.hdwlinux.programs.simplescan = {
    enable = config.lib.hdwlinux.mkEnableOption "simplescan" [
      "gui"
      "scanning"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.simple-scan ];
  };
}
