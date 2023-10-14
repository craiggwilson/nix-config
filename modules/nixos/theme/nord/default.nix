{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.nord; 
in {

  options.hdwlinux.theme.nord = with types; {
    enable = mkBoolOpt false "Whether or not to enable the nord theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      wallpaper1 = ./assets/wild.png;
      wallpaper2 = ./assets/wild.png;
      wallpaper3 = ./assets/wild.png;

      color0 = "2e3440";
      color1 = "3b4252";
      color2 = "434c5e";
      color3 = "4c566a";

      color4 = "d8dee9";
      color5 = "e5e9f0";
      color6 = "eceff4";

      color7 = "8fbcbb";
      color8 = "88c0d0";
      color9 = "81a1c1";
      color10 = "5e81ac";
      color11 = "bf616a";

      color12 = "d08770";
      color13 = "ebcb8b";
      color14 = "a3be8c";
      color15 = "b48ead";
    };

    # Do some extra stuff here...
    hdwlinux.home = {
      programs.vscode.userSettings = {
        "workbench.colorTheme" = "Nord Deep";
      };
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
  };
}
