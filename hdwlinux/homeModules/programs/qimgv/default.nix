{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.qimgv;
  pkg = pkgs.qimgv;
in
{
  options.hdwlinux.programs.qimgv = {
    enable = config.lib.hdwlinux.mkEnableOption "qimgv" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkg ];

    hdwlinux.apps.imageViewer = {
      package = pkg;
      desktopName = "qimgv.desktop";
    };
  };
}
