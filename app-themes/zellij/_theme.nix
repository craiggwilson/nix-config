# Renders the "hdwlinux" zellij theme file that lands in
# ~/.config/zellij/themes/. Expects the colorLib attrset (as returned by
# lib/colors.nix): zellij takes "r g b" integers, which colorLib exposes as
# each color's `rgbString`.
colors:
let
  # Shorthand aliases for readability
  bg = colors.base00; # base background
  surface = colors.base02; # mid background
  subtle = colors.base04; # subdued text
  text = colors.base05; # white text
  blue = colors.base0D; # accent / tabs / ribbons
  mauve = colors.base0E; # frame highlight
  green = colors.base0B; # success
  red = colors.base08; # error

  component =
    base: background: emphasis_0: emphasis_1: emphasis_2: emphasis_3: {
      inherit
        base
        background
        emphasis_0
        emphasis_1
        emphasis_2
        emphasis_3
        ;
    };

  concat = builtins.concatStringsSep "";

  indent = depth: concat (builtins.genList (i: "\t") depth);

  # Keys are emitted in sorted order, which is the order zellij's own theme
  # generator produced: background, base, emphasis_0..3.
  block =
    name: entries:
    "${indent 2}${name} {\n"
    + concat (
      map (key: "${indent 3}${key} ${entries.${key}.rgbString}\n") (builtins.attrNames entries)
    )
    + "${indent 2}}\n";

  components = {
    text_unselected = component subtle bg blue mauve green text;
    text_selected = component text surface blue mauve green text;
    ribbon_unselected = component text surface blue mauve green text;
    ribbon_selected = component bg blue bg mauve green text;
    table_title = component blue bg blue mauve green text;
    table_cell_unselected = component subtle bg blue mauve green text;
    table_cell_selected = component text surface blue mauve green text;
    list_unselected = component subtle bg blue mauve green text;
    list_selected = component text surface blue mauve green text;
    frame_unselected = component surface bg blue mauve green text;
    frame_selected = component blue bg blue mauve green text;
    frame_highlight = component mauve bg blue mauve green text;
    exit_code_success = component green bg green green green green;
    exit_code_error = component red bg red red red red;
    multiplayer_user_colors = {
      player_1 = colors.base0D;
      player_2 = colors.base0B;
      player_3 = colors.base0A;
      player_4 = colors.base0E;
      player_5 = colors.base0C;
      player_6 = colors.base09;
      player_7 = colors.base08;
      player_8 = colors.base0F;
      player_9 = colors.base04;
      player_10 = colors.base05;
    };
  };
in
"themes {\n${indent 1}hdwlinux {\n"
+ concat (map (name: block name components.${name}) (builtins.attrNames components))
+ "${indent 1}}\n}\n"
