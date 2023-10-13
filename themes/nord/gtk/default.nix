{ lib, pkgs, config, ... }:
{
  hdwlinux.home = {
    sessionVariables = {
      GTK_THEME = "Nordic-darker";
    };
    extraOptions.gtk = {
      enable = true;
      theme = {
        name = "Nordic-darker";
        package = pkgs.nordic;
      };
      iconTheme = {
        name = "Nordzy-dark";
        package = pkgs.nordzy-icon-theme;
      };
      cursorTheme = {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };
}
