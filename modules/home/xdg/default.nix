{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.xdg;
in
{
  options.hdwlinux.xdg = {
    enable = lib.hdwlinux.mkEnableOption "xdg" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ xdg-utils ];

    xdg = {
      enable = true;
      mime.enable = true;
      mimeApps.enable = true;
      configFile."mimeapps.list".force = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
        };
      };
    };
  };
}
