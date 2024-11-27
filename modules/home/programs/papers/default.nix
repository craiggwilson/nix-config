{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.papers;
in
{
  options.hdwlinux.programs.papers = {
    enable = config.lib.hdwlinux.mkEnableOption "papers" "gui";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.apps.documentViewer = {
      package = pkgs.papers;
      desktopName = "org.gnome.Papers.desktop";
    };

    home.packages = [ pkgs.papers ];
  };
}
