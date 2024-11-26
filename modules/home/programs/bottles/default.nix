{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.bottles;
in
{
  options.hdwlinux.programs.bottles = {
    enable = config.lib.hdwlinux.mkEnableOption "bottles" [
      "gaming"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bottles ];
  };
}
