{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.theme.catppuccin-mocha;
  accent = "lavender";
  flavor = "mocha";
  gtkName = "catppuccin-${flavor}-${accent}-standard";
  cursorThemeName = "catppuccin-${flavor}-dark-cursors";
  gtkPkg = pkgs.catppuccin-gtk.override {
    accents = [ accent ];
    variant = flavor;
  };
  kvantumName = "catppuccin-${flavor}-${accent}";
  kvantumPkg = pkgs.catppuccin-kvantum.override {
    accent = accent;
    variant = flavor;
  };
  wallpaper = ./assets/cat-waves.png;
in
{

  options.hdwlinux.theme.catppuccin-mocha = {
    enable = lib.hdwlinux.mkBoolOpt false "Whether or not to enable the catppuccin-mocha theme.";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.theme = {
      enable = lib.mkDefault true;
      name = "catppuccin-${lib.toLower flavor}";
      colors = inputs.themes.catppuccin-mocha;
      wallpapers = [ wallpaper ];
    };

    # GTK
    gtk = {
      theme = {
        name = gtkName;
        package = gtkPkg;
      };

      cursorTheme = lib.mkDefault {
        name = cursorThemeName;
        package = pkgs.catppuccin-cursors.mochaDark;
      };

      iconTheme = lib.mkDefault {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = lib.toLower accent;
          flavor = lib.toLower flavor;
        };
      };
    };

    home.sessionVariables.GTK_THEME = gtkName;
    home.sessionVariables.XCURSOR_THEME = cursorThemeName;

    # QT
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style = {
        name = "kvantum";
      };
    };

    xdg.configFile = {
      "Kvantum/${kvantumName}/${kvantumName}/${kvantumName}.kvconfig".source = "${kvantumPkg}/share/Kvantum/${kvantumName}/${kvantumName}.kvconfig";
      "Kvantum/${kvantumName}/${kvantumName}/${kvantumName}.svg".source = "${kvantumPkg}/share/Kvantum/${kvantumName}/${kvantumName}.svg";
      "Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=${kvantumName}
      '';
    };

    # VSCode
    hdwlinux.features.vscode.theme = "Catppuccin ${flavor}";
    programs.vscode.extensions = with pkgs.vscode-extensions; [ catppuccin.catppuccin-vsc ];
  };
}
