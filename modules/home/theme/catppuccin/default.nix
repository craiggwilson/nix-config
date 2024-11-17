{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.theme.catppuccin;
  gtkName = "catppuccin-${cfg.flavor}-${cfg.accent}-standard";
  gtkPkg = pkgs.catppuccin-gtk.override {
    accents = [ cfg.accent ];
    variant = cfg.flavor;
  };
  kvantumName = "catppuccin-${cfg.flavor}-${cfg.accent}";
  kvantumPkg = pkgs.catppuccin-kvantum.override {
    accent = cfg.accent;
    variant = cfg.flavor;
  };
  wallpaper = ./assets/cat-waves.png;
in
{

  options.hdwlinux.theme.catppuccin = {
    enable = lib.hdwlinux.mkBoolOpt false "Whether or not to enable the catppuccin theme.";
    flavor = lib.hdwlinux.mkStrOpt "mocha" "The catppuccin flavor.";
    accent = lib.hdwlinux.mkStrOpt "lavender" "The catppuccin accent";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.theme = {
      enable = lib.mkDefault true;
      name = "catppuccin-${cfg.flavor}";
      colors = inputs.themes.${"catppuccin-" + cfg.flavor};
      wallpapers = [ wallpaper ];
    };

    # Cursor
    home.pointerCursor = lib.mkIf cfg.enable {
      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors";
      # package = pkgs.catppuccin-cursors.${cfg.flavor + lib.hdwlinux.toTitle cfg.accent};
      # name = "catppuccin-${cfg.flavor}-${cfg.accent}-cursors";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      HYPRCURSOR_THEME = config.home.pointerCursor.name;
      HYPRCURSOR_SIZE = config.home.pointerCursor.size;
    };

    wayland.windowManager.hyprland.settings.env = [
      "HYPRCURSOR_THEME,${config.home.pointerCursor.name}"
      "HYPRCURSOR_SIZE,${toString config.home.pointerCursor.size}"
    ];

    # GTK
    gtk = {
      theme = {
        name = gtkName;
        package = gtkPkg;
      };

      iconTheme = lib.mkDefault {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = lib.toLower cfg.accent;
          flavor = lib.toLower cfg.flavor;
        };
      };
    };

    home.sessionVariables.GTK_THEME = gtkName;

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
    hdwlinux.features.vscode.theme = "Catppuccin ${lib.hdwlinux.toTitle cfg.flavor}";
    programs.vscode.extensions = with pkgs.vscode-extensions; [ catppuccin.catppuccin-vsc ];
  };
}
