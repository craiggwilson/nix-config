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
  wallpaper = ./assets/fishing_stars.jpg;
in
{

  options.hdwlinux.theme.catppuccin = {
    enable = config.lib.hdwlinux.mkEnableOption "catppuccin" "theming:catppuccin";
    flavor = lib.mkOption {
      description = "The flavor.";
      type = lib.types.str;
      default = "mocha";
    };
    accent = lib.mkOption {
      description = "The accent.";
      type = lib.types.str;
      default = "lavender";
    };
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.theme = {
      enable = lib.mkDefault true;
      name = "catppuccin-${cfg.flavor}";
      colors = inputs.themes.${"catppuccin-" + cfg.flavor};
      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        # package = pkgs.catppuccin-cursors.${cfg.flavor + lib.hdwlinux.toTitle cfg.accent};
        # name = "catppuccin-${cfg.flavor}-${cfg.accent}-cursors";
        size = 24;
      };
      dark = true;
      wallpapers = [ wallpaper ];
    };

    # GTK
    gtk = {
      theme = {
        name = gtkName;
        package = gtkPkg;
      };

      iconTheme = lib.mkDefault {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = cfg.accent;
          flavor = cfg.flavor;
        };
      };
    };

    home.sessionVariables.GTK_THEME = gtkName;

    # QT
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
    };

    xdg.configFile = {
      "Kvantum/${kvantumName}".source = "${kvantumPkg}/share/Kvantum/${kvantumName}";
      "Kvantum/kvantum.kvconfig".source = (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
        General.theme = kvantumName;
      };
    };

    # VSCode
    hdwlinux.programs.vscode.theme = "Catppuccin ${lib.hdwlinux.toTitle cfg.flavor}";
    programs.vscode.extensions = with pkgs.vscode-extensions; [ catppuccin.catppuccin-vsc ];
  };
}
