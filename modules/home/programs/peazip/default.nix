{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.peazip;
in
{
  options.hdwlinux.programs.peazip = {
    enable = config.lib.hdwlinux.mkEnableOption "peazip" "gui";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.apps.archiver = {
      package = pkgs.peazip;
      desktopName = "peazip.desktop";
    };

    home.packages = [ pkgs.peazip ];
  };
}
