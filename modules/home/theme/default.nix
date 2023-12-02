{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.theme;
in {
  options.hdwlinux.theme = with types; {
    enable = mkBoolOpt false "Whether or not to enable themes.";
    colors = mkOpt attrs {} "The current colors.";

    wallpapers = mkOption {
      description = "The wallpapers for the system.";
      type = listOf path;
    };
  };

  config = mkIf cfg.enable {
    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk3.extraCss = cfg.colors.adwaitaGtkCss;
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraCss = cfg.colors.adwaitaGtkCss;
      cursorTheme = {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
      };
      iconTheme = {
        name = "Nordzy-dark";
        package = pkgs.nordzy-icon-theme;
      };
    };
  };
}
