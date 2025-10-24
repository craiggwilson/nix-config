{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.protonup-qt;
in
{
  options.hdwlinux.programs.protonup-qt = {
    enable = config.lib.hdwlinux.mkEnableOption "protonup-qt" [
      "gui"
      "gaming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.protonup-qt ];
  };
}
