{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.thunar;
in
{
  options.hdwlinux.desktopManagers.hyprland.thunar = {
    enable = lib.mkOption {
      description = "Whether to enable thunar.";
      type = lib.types.bool;
      default = config.hdwlinux.desktopManagers.hyprland.enable;
    };
  };

  config = lib.mkIf cfg.enable {
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
