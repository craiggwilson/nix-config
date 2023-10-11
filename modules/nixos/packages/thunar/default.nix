{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.thunar;
in
{
  options.hdwlinux.packages.thunar = with types; {
    enable = mkBoolOpt false "Whether or not to enable thunar.";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images

    xdg.mime.defaultApplications."inode/directory" = "thunar.desktop";
  };
}
