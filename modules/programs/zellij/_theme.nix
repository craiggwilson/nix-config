# Returns a programs.zellij.themes-compatible attrset for the "hdwlinux" theme.
# Expects the colorLib attrset (as returned by lib/colors.nix), which provides
# bare hex color attributes (base00..base0F) and toRgb.
colors:
let
  rgb = colors.toRgb;

  mkComponent =
    {
      base,
      background,
      emphasis_0,
      emphasis_1,
      emphasis_2,
      emphasis_3,
    }:
    {
      base = rgb base;
      background = rgb background;
      emphasis_0 = rgb emphasis_0;
      emphasis_1 = rgb emphasis_1;
      emphasis_2 = rgb emphasis_2;
      emphasis_3 = rgb emphasis_3;
    };

  # Shorthand aliases for readability
  bg = colors.base00; # base background
  surface = colors.base02; # mid background
  subtle = colors.base04; # subdued text
  text = colors.base05; # white text
  blue = colors.base0D; # accent / tabs / ribbons
  mauve = colors.base0E; # frame highlight
  green = colors.base0B; # success
  red = colors.base08; # error
in
{
  text_unselected = mkComponent {
    base = subtle;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  text_selected = mkComponent {
    base = text;
    background = surface;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  ribbon_unselected = mkComponent {
    base = text;
    background = surface;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  ribbon_selected = mkComponent {
    base = bg;
    background = blue;
    emphasis_0 = bg;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  table_title = mkComponent {
    base = blue;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  table_cell_unselected = mkComponent {
    base = subtle;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  table_cell_selected = mkComponent {
    base = text;
    background = surface;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  list_unselected = mkComponent {
    base = subtle;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  list_selected = mkComponent {
    base = text;
    background = surface;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  frame_unselected = mkComponent {
    base = surface;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  frame_selected = mkComponent {
    base = blue;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  frame_highlight = mkComponent {
    base = mauve;
    background = bg;
    emphasis_0 = blue;
    emphasis_1 = mauve;
    emphasis_2 = green;
    emphasis_3 = text;
  };
  exit_code_success = mkComponent {
    base = green;
    background = bg;
    emphasis_0 = green;
    emphasis_1 = green;
    emphasis_2 = green;
    emphasis_3 = green;
  };
  exit_code_error = mkComponent {
    base = red;
    background = bg;
    emphasis_0 = red;
    emphasis_1 = red;
    emphasis_2 = red;
    emphasis_3 = red;
  };
  multiplayer_user_colors = {
    player_1 = rgb colors.base0D;
    player_2 = rgb colors.base0B;
    player_3 = rgb colors.base0A;
    player_4 = rgb colors.base0E;
    player_5 = rgb colors.base0C;
    player_6 = rgb colors.base09;
    player_7 = rgb colors.base08;
    player_8 = rgb colors.base0F;
    player_9 = rgb colors.base04;
    player_10 = rgb colors.base05;
  };
}
