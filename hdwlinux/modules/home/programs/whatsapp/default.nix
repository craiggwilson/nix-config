{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.whatsapp;
in
{
  options.hdwlinux.programs.whatsapp = {
    enable = config.lib.hdwlinux.mkEnableOption "whatsapp" [
      "gui"
      "personal"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.whatsapp-for-linux ];
  };
}
