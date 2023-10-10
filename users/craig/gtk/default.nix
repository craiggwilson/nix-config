{ lib, pkgs, config, ... }:
{
  hdwlinux.home = {
    extraOptions.gtk = {
      enable = true;
      theme = {
        name = "Nordic-darker";
        package = pkgs.nordic;
      };
      iconTheme = {
        name = "Nordzy";
        package = pkgs.nordzy-icon-theme;
      };
      cursorTheme = {
        name = "Nordzy";
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
