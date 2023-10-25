{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.theme;
in {
  options.hdwlinux.features.theme = with types; {
    enable = mkBoolOpt false "Whether or not to enable themes.";
    wallpapers = mkOption {
      description = "The wallpapers for the system.";
      type = listOf path;
    };
  };

  config = {
    stylix = {
      image = builtins.elemAt cfg.wallpapers 0;
      polarity = "dark";
      autoEnable = true;
      fonts = {
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };

        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };

        monospace = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans Mono";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
      };
    };

    stylix.targets = {
      gnome.enable = mkForce false;
      waybar.enable = false;
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Nordzy-dark";
        package = pkgs.nordzy-icon-theme;
      };
      cursorTheme = {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
      };
    };
  };
}
