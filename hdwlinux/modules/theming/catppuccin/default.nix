let
  # Catppuccin Mocha color palette
  flavor = "mocha";
  accent = "lavender";
  wallpaper = ./assets/fishing_stars.jpg;

  colors = {
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

  # Pre-compute withHashtag version
  withHashtag = builtins.mapAttrs (_: value: "#" + value) colors;

  # Generate adwaita GTK CSS
  adwaitaGtkCss = with withHashtag; ''
    @define-color accent_color ${base0A};
    @define-color accent_bg_color ${base0A};
    @define-color accent_fg_color ${base00};
    @define-color destructive_color ${base08};
    @define-color destructive_bg_color ${base08};
    @define-color destructive_fg_color ${base00};
    @define-color success_color ${base0B};
    @define-color success_bg_color ${base0B};
    @define-color success_fg_color ${base00};
    @define-color warning_color ${base0E};
    @define-color warning_bg_color ${base0E};
    @define-color warning_fg_color ${base00};
    @define-color error_color ${base08};
    @define-color error_bg_color ${base08};
    @define-color error_fg_color ${base00};
    @define-color window_bg_color ${base00};
    @define-color window_fg_color ${base05};
    @define-color view_bg_color ${base00};
    @define-color view_fg_color ${base05};
    @define-color headerbar_bg_color ${base01};
    @define-color headerbar_fg_color ${base05};
    @define-color headerbar_border_color ${base01};
    @define-color headerbar_backdrop_color @window_bg_color;
    @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
    @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
    @define-color sidebar_bg_color ${base01};
    @define-color sidebar_fg_color ${base05};
    @define-color sidebar_backdrop_color @window_bg_color;
    @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
    @define-color card_bg_color ${base01};
    @define-color card_fg_color ${base05};
    @define-color card_shade_color rgba(0, 0, 0, 0.07);
    @define-color dialog_bg_color ${base01};
    @define-color dialog_fg_color ${base05};
    @define-color popover_bg_color ${base01};
    @define-color popover_fg_color ${base05};
    @define-color popover_shade_color rgba(0, 0, 0, 0.07);
    @define-color shade_color rgba(0, 0, 0, 0.07);
    @define-color scrollbar_outline_color ${base02};
  '';

  # Pre-compute the full theme with all derived attributes
  themeColors = colors // {
    inherit withHashtag adwaitaGtkCss;
  };
in
{
  config.substrate.modules.theming.catppuccin = {
    tags = [ "theming:catppuccin" ];

    nixos = {
      console.colors = [
        "1e1e2e"
        "f38ba8"
        "a6e3a1"
        "f9e2af"
        "89b4fa"
        "f5c2e7"
        "94e2d5"
        "cdd6f4"

        "585b70"
        "f38ba8"
        "a6e3a1"
        "f9e2af"
        "89b4fa"
        "f5c2e7"
        "94e2d5"
        "b4befe"
      ];
    };

    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      let
        gtkName = "catppuccin-${flavor}-${accent}-standard";
        gtkPkg = pkgs.catppuccin-gtk.override {
          accents = [ accent ];
          variant = flavor;
        };
        kvantumName = "catppuccin-${flavor}-${accent}";
        kvantumPkg = pkgs.catppuccin-kvantum.override {
          inherit accent;
          variant = flavor;
        };
      in
      {
        hdwlinux.theme = {
          name = "catppuccin-${flavor}";
          colors = themeColors;
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
          enable = true;
          theme = {
            name = gtkName;
            package = gtkPkg;
          };

          iconTheme = lib.mkDefault {
            name = "Papirus-Dark";
            package = pkgs.catppuccin-papirus-folders.override {
              accent = accent;
              flavor = flavor;
            };
          };

          gtk3.extraCss = themeColors.adwaitaGtkCss;
          gtk4.extraCss = themeColors.adwaitaGtkCss;
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
      };
  };
}
