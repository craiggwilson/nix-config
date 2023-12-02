{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gtk;
in
{
  options.hdwlinux.features.gtk = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config.gtk = mkIf cfg.enable {
    enable = true;

    gtk3 = mkIf config.hdwlinux.theme.enable {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      extraCss = config.hdwlinux.theme.colors.adwaitaGtkCss;
    };
    gtk4 = mkIf config.hdwlinux.theme.enable {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      extraCss = config.hdwlinux.theme.colors.adwaitaGtkCss;
    };

    cursorTheme = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
    };
    iconTheme = {
      name = "Nordzy-dark";
      package = pkgs.nordzy-icon-theme;
    };
  };
}
