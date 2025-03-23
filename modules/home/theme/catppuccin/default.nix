{
  lib,
  pkgs,
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
      colors = lib.hdwlinux.theme.fromAttrs {
        base00 = "1e1e2e"; # base
        base01 = "181825"; # mantle
        base02 = "313244"; # surface0
        base03 = "45475a"; # surface1
        base04 = "585b70"; # surface2
        base05 = "cdd6f4"; # text
        base06 = "f5e0dc"; # rosewater
        base07 = "b4befe"; # lavender
        base08 = "f38ba8"; # red
        base09 = "fab387"; # peach
        base0A = "f9e2af"; # yellow
        base0B = "a6e3a1"; # green
        base0C = "94e2d5"; # teal
        base0D = "89b4fa"; # blue
        base0E = "cba6f7"; # mauve
        base0F = "f2cdcd"; # flamingo
        base10 = "181825"; # mantle - darker background
        base11 = "11111b"; # crust - darkest background
        base12 = "eba0ac"; # maroon - bright red
        base13 = "f5e0dc"; # rosewater - bright yellow
        base14 = "a6e3a1"; # green - bright green
        base15 = "89dceb"; # sky - bright cyan
        base16 = "74c7ec"; # sapphire - bright blue
        base17 = "f5c2e7"; # pink - bright purple
      };
      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 24;
      };
      dark = true;
      wallpaper = wallpaper;
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
