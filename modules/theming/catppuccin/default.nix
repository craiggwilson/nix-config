# Catppuccin Mocha: pushes its palette into the substrate theming registry
# and applies the surfaces that go beyond raw colors (GTK/Kvantum/theme
# files, wallpaper). Application is gated on `theming.active` selecting this
# palette; color consumers read the derived hdwlinux.theme.colors view.
let
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
  ansiColors = {
    black = colors.base00; # base
    red = colors.base08; # red
    green = colors.base0B; # green
    yellow = colors.base0A; # yellow
    blue = colors.base0D; # blue
    magenta = colors.base06; # rosewater
    cyan = colors.base0C; # teal
    white = colors.base05; # text
    brightBlack = colors.base04; # surface2
    brightRed = colors.base12; # maroon
    brightGreen = colors.base14; # green (bright)
    brightYellow = colors.base13; # rosewater (bright yellow)
    brightBlue = colors.base16; # sapphire
    brightMagenta = colors.base17; # pink
    brightCyan = colors.base15; # sky
    brightWhite = colors.base07; # lavender
  };

  # Maps every unique base24 palette hex to its nearest ANSI slot name.
  # base10 = base01, base13 = base06, base14 = base0B — omitted as duplicates.
  paletteToAnsi = {
    ${colors.base00} = "black";
    ${colors.base01} = "black";
    ${colors.base02} = "black";
    ${colors.base03} = "brightBlack";
    ${colors.base04} = "brightBlack";
    ${colors.base05} = "white";
    ${colors.base06} = "magenta";
    ${colors.base07} = "brightWhite";
    ${colors.base08} = "red";
    ${colors.base09} = "yellow";
    ${colors.base0A} = "yellow";
    ${colors.base0B} = "green";
    ${colors.base0C} = "cyan";
    ${colors.base0D} = "blue";
    ${colors.base0E} = "brightMagenta";
    ${colors.base0F} = "brightRed";
    ${colors.base11} = "black";
    ${colors.base12} = "brightRed";
    ${colors.base15} = "brightCyan";
    ${colors.base16} = "brightBlue";
    ${colors.base17} = "brightMagenta";
  };

  gtkName = "catppuccin-${flavor}-${accent}-standard";
  kvantumName = "catppuccin-${flavor}-${accent}";
in
{
  config.substrate.settings.theming.palettes."catppuccin-mocha" = {
    inherit colors;
    ansi = ansiColors;
    ansiMap = paletteToAnsi;
    dark = true;
    gtk = {
      name = gtkName;
      package =
        pkgs:
        pkgs.catppuccin-gtk.override {
          accents = [ accent ];
          variant = flavor;
        };
    };
    icon = {
      name = "Papirus-Dark";
      package =
        pkgs:
        pkgs.catppuccin-papirus-folders.override {
          inherit accent flavor;
        };
    };
    cursor = {
      name = "Nordzy-cursors";
      package = pkgs: pkgs.nordzy-cursor-theme;
      size = 24;
    };
  };

  config.substrate.modules.theming.catppuccin = {
    tags = [ "theming:catppuccin" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        theme,
        ...
      }:
      let
        palette = theme.palettes."catppuccin-mocha";

        # Generate adwaita GTK CSS
        adwaitaGtkCss = with palette.colors.hexWithHashtag; ''
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

        gtkPkg = palette.gtk.package pkgs;
        iconPkg = palette.icon.package pkgs;
        kvantumPkg = pkgs.catppuccin-kvantum.override {
          inherit accent;
          variant = flavor;
        };
      in
      {
        config = lib.mkIf (config.theming.active == "catppuccin-mocha") {
          hdwlinux.theme.wallpaper = wallpaper;

          # GTK
          gtk = {
            enable = true;
            theme = {
              name = gtkName;
              package = gtkPkg;
            };
            gtk4.theme = {
              name = gtkName;
              package = gtkPkg;
            };

            iconTheme = lib.mkDefault {
              name = "Papirus-Dark";
              package = iconPkg;
            };

            gtk3.extraCss = adwaitaGtkCss;
            gtk4.extraCss = adwaitaGtkCss;
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
  };
}
