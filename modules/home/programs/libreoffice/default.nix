{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.libreoffice;
in
{
  options.hdwlinux.programs.libreoffice = {
    enable = config.lib.hdwlinux.mkEnableOption "libreoffice" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.libreoffice ];
  };
}
