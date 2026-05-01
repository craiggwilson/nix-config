# Returns a programs.zellij.themes-compatible attrset for the "hdwlinux" theme.
# Expects the colorLib attrset (as returned by lib/colors.nix). Each baseXX
# entry is a color object; zellij themes use [r g b] integer lists.
colors:
let
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
      base = base;
      background = background;
      emphasis_0 = emphasis_0;
      emphasis_1 = emphasis_1;
      emphasis_2 = emphasis_2;
      emphasis_3 = emphasis_3;
    };

  # Shorthand aliases for readability
  bg = colors.base00.rgb; # base background
  surface = colors.base02.rgb; # mid background
  subtle = colors.base04.rgb; # subdued text
  text = colors.base05.rgb; # white text
  blue = colors.base0D.rgb; # accent / tabs / ribbons
  mauve = colors.base0E.rgb; # frame highlight
  green = colors.base0B.rgb; # success
  red = colors.base08.rgb; # error
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
    player_1 = colors.base0D.rgb;
    player_2 = colors.base0B.rgb;
    player_3 = colors.base0A.rgb;
    player_4 = colors.base0E.rgb;
    player_5 = colors.base0C.rgb;
    player_6 = colors.base09.rgb;
    player_7 = colors.base08.rgb;
    player_8 = colors.base0F.rgb;
    player_9 = colors.base04.rgb;
    player_10 = colors.base05.rgb;
  };
}
