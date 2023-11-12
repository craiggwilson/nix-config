{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.xdg;
in
{
  options.hdwlinux.features.xdg = with types; {
    enable = mkBoolOpt true "Whether or not to configure xdg.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      xdg-utils
    ];

    xdg = {
      enable = true;
      mime.enable = true;
      mimeApps.enable = true;
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
