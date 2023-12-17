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
        gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
      };
      extraCss = mkIf (config.gtk.theme == null) config.hdwlinux.theme.colors.adwaitaGtkCss;
    };
    gtk4 = mkIf config.hdwlinux.theme.enable {
      extraConfig = {
        gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
      };
      extraCss = mkIf (config.gtk.theme == null) config.hdwlinux.theme.colors.adwaitaGtkCss;
    };

    cursorTheme = mkDefault {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
    };
    iconTheme = mkDefault {
      name = "Nordzy-dark";
      package = pkgs.nordzy-icon-theme;
    };
  };
}
