# Catppuccin Mocha palette registration. All colors are bare hex (no
# leading #); ANSI slots and the palette→ANSI map drive the TTY/terminal
# surfaces. The substrate theming extension applies the described surfaces
# (GTK, cursor, Qt/Kvantum, console, Plymouth) to any host/user configuration
# that sets theming.active to "catppuccin-mocha"; per-app theme fragments
# read config.theming.palette.
let
  flavor = "mocha";
  accent = "lavender";

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
in
{
  config.substrate.settings.theming.palettes."catppuccin-${flavor}" = {
    inherit colors;
    dark = true;
    ansi = ansiColors;
    ansiMap = paletteToAnsi;
    gtk = {
      name = "catppuccin-${flavor}-${accent}-standard";
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
    qt = {
      name = "catppuccin-${flavor}-${accent}";
      package =
        pkgs:
        pkgs.catppuccin-kvantum.override {
          inherit accent;
          variant = flavor;
        };
      platformTheme = "qtct";
    };
    plymouth = {
      name = "catppuccin-${flavor}";
      package =
        pkgs:
        pkgs.catppuccin-plymouth.override {
          variant = flavor;
        };
    };
    wallpapers = [ ./assets/fishing_stars.jpg ];
  };
}
