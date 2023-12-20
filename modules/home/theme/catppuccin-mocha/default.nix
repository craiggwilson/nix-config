{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.catppuccin-mocha;
  name = "Catppuccin-Mocha-Standard-Lavender-Dark"; 
  wallpaper = ./assets/cat-waves.png;
in {

  options.hdwlinux.theme.catppuccin-mocha = with types; {
    enable = mkBoolOpt false "Whether or not to enable the catppuccin-mocha theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      enable = mkDefault true;
      colors = inputs.themes.catppuccin-mocha;
      wallpapers = [ wallpaper ];
    };

    # GTK
    gtk = {
      theme = {
        name = name;
        package = pkgs.catppuccin-gtk.override {
          accents = ["lavender"];
          variant = "mocha";
        };
      };

      cursorTheme = mkDefault {
        name = "Catppuccin-Mocha-Dark-Cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
      };

      iconTheme = mkDefault {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = "lavender";
          flavor = "mocha";
        };
      };
    };

    home.sessionVariables.GTK_THEME = name;

    dconf.settings = mkIf config.hdwlinux.features.gnome.enable {
      "org/gnome/shell/extensions/user-theme" = {
        name = name;
      };
    };

    # VSCode
    hdwlinux.features.vscode.theme = "Catppuccin Mocha";
    programs.vscode.extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
    ];
  };
}
