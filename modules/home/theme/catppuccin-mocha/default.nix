{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme.catppuccin-mocha;
  accent = "Lavender";
  flavor = "Mocha";
  gtkName = "Catppuccin-${flavor}-Standard-${accent}-Dark"; 
  kvantumName = "Catppuccin-${flavor}-${accent}";
  kvantumPkg = pkgs.catppuccin-kvantum.override {
    accent = accent;
    variant = flavor;
  };
  wallpaper = ./assets/cat-waves.png;
in {

  options.hdwlinux.theme.catppuccin-mocha = with types; {
    enable = mkBoolOpt false "Whether or not to enable the catppuccin-mocha theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      enable = mkDefault true;
      name = "catppuccin-mocha";
      colors = inputs.themes.catppuccin-mocha;
      wallpapers = [ wallpaper ];
    };

    # GTK
    gtk = {
      theme = {
        name = gtkName;
        package = pkgs.catppuccin-gtk.override {
          accents = [(lib.toLower accent)];
          variant = lib.toLower flavor;
        };
      };

      cursorTheme = mkDefault {
        name = "Catppuccin-${flavor}-Dark-Cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
      };

      iconTheme = mkDefault {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = lib.toLower accent;
          flavor = lib.toLower flavor;
        };
      };
    };

    home.sessionVariables.GTK_THEME = gtkName;

    dconf.settings = mkIf config.hdwlinux.features.gnome.enable {
      "org/gnome/shell/extensions/user-theme" = {
        name = gtkName;
      };
    };

    # QT
    qt = {
      enable = true;
      platformTheme = "qtct";
      style = {
        name = "kvantum";
      };
    };

    xdg.configFile."Kvantum/${kvantumName}/${kvantumName}/${kvantumName}.kvconfig".source = "${kvantumPkg}/share/Kvantum/${kvantumName}/${kvantumName}.kvconfig";
    xdg.configFile."Kvantum/${kvantumName}/${kvantumName}/${kvantumName}.svg".source = "${kvantumPkg}/share/Kvantum/${kvantumName}/${kvantumName}.svg";
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=${kvantumName}
    '';

    # VSCode
    hdwlinux.features.vscode.theme = "Catppuccin ${flavor}";
    programs.vscode.extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
    ];
  };
}
