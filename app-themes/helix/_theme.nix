# Returns a programs.helix.themes-compatible attrset for the "hdwlinux"
# theme. Expects the colorLib attrset (as returned by lib/colors.nix); helix
# themes use "#rrggbb" hex strings.
colors:
let
  hex = builtins.mapAttrs (_: c: c.hexWithHashtag) colors;
in
{

  attribute = hex.base0A;
  comment = {
    fg = hex.base04;
    modifiers = [ "italic" ];
  };
  constant = hex.base09;
  "constant.numeric" = hex.base09;
  "constant.character.escape" = hex.base0C;
  diagnostic = hex.base08;
  "diagnostic.error" = hex.base08;
  "diagnostic.warning" = hex.base0A;
  "diagnostic.info" = hex.base0C;
  "diagnostic.hint" = hex.base0D;
  error = hex.base08;
  hint = hex.base0D;
  keyword = hex.base0E;
  "keyword.control" = hex.base0E;
  "keyword.directive" = hex.base0E;
  label = hex.base0D;
  "markup.bold" = {
    fg = hex.base05;
    modifiers = [ "bold" ];
  };
  "markup.heading" = hex.base07;
  "markup.italic" = {
    fg = hex.base05;
    modifiers = [ "italic" ];
  };
  "markup.link.text" = hex.base0D;
  "markup.link.url" = {
    fg = hex.base0C;
    modifiers = [ "underlined" ];
  };
  "markup.list" = hex.base0E;
  "markup.quote" = hex.base04;
  "markup.raw" = hex.base0B;
  operator = hex.base0F;
  option = hex.base0D;
  prompt = hex.base0B;
  selection = {
    bg = hex.base02;
    fg = hex.base05;
  };
  special = hex.base0C;
  string = hex.base0B;
  "string.regexp" = hex.base0C;
  "string.special" = hex.base0D;
  tag = hex.base0E;
  "ui.background" = {
    fg = hex.base05;
    bg = hex.base00;
  };
  "ui.bufferline" = {
    fg = hex.base04;
    bg = hex.base01;
  };
  "ui.bufferline.active" = {
    fg = hex.base00;
    bg = hex.base07;
    modifiers = [ "bold" ];
  };
  "ui.cursor" = {
    fg = hex.base00;
    bg = hex.base07;
  };
  "ui.cursor.insert" = {
    fg = hex.base00;
    bg = hex.base0B;
  };
  "ui.cursor.match" = {
    fg = hex.base00;
    bg = hex.base0A;
  };
  "ui.cursor.normal" = {
    fg = hex.base00;
    bg = hex.base07;
  };
  "ui.cursor.select" = {
    fg = hex.base00;
    bg = hex.base0E;
  };
  "ui.gutter" = {
    fg = hex.base04;
    bg = hex.base01;
  };
  "ui.gutter.selected" = {
    fg = hex.base07;
    bg = hex.base01;
  };
  "ui.help" = {
    fg = hex.base05;
    bg = hex.base01;
  };
  "ui.linenr" = {
    fg = hex.base04;
    bg = hex.base01;
  };
  "ui.linenr.selected" = {
    fg = hex.base07;
    bg = hex.base01;
  };
  "ui.menu" = {
    fg = hex.base05;
    bg = hex.base01;
  };
  "ui.menu.selected" = {
    fg = hex.base00;
    bg = hex.base07;
  };
  "ui.popup" = {
    fg = hex.base05;
    bg = hex.base01;
  };
  "ui.selection" = {
    fg = hex.base05;
    bg = hex.base02;
  };
  "ui.selection.primary" = {
    fg = hex.base05;
    bg = hex.base03;
  };
  "ui.statusline" = {
    fg = hex.base05;
    bg = hex.base01;
  };
  "ui.statusline.inactive" = {
    fg = hex.base04;
    bg = hex.base01;
  };
  "ui.statusline.insert" = {
    fg = hex.base00;
    bg = hex.base0B;
  };
  "ui.statusline.normal" = {
    fg = hex.base00;
    bg = hex.base07;
  };
  "ui.statusline.select" = {
    fg = hex.base00;
    bg = hex.base0E;
  };
  "ui.text" = hex.base05;
  "ui.text.focus" = hex.base07;
  "ui.virtual" = hex.base03;
  "ui.virtual.indent-guide" = hex.base02;
  "ui.virtual.ruler" = hex.base02;
  warning = hex.base0A;
}
