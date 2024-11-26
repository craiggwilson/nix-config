{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.slack;
in
{
  options.hdwlinux.programs.slack = {
    enable = config.lib.hdwlinux.mkEnableOption "slack" [
      "gui"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.slack ];
  };
}
