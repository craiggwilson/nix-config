{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.cava;
in
{
  options.hdwlinux.programs.cava = {
    enable = config.lib.hdwlinux.mkEnableOption "cava" "audio";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cava ];
  };
}
