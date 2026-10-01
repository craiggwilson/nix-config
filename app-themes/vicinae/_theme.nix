# Renders the "hdwlinux" vicinae theme file
# (~/.config/vicinae/themes/hdwlinux.toml). Expects the colorLib attrset as
# returned by lib/colors.nix; vicinae wants "#rrggbb" hex strings.
colors:
let
  hex = builtins.mapAttrs (_: c: c.hexWithHashtag) colors;
in
{

  meta = {
    version = 1;
    name = "hdwlinux";
    description = "HDW Linux theme using base16 colors";
    variant = "dark";
  };
  colors = {
    core = {
      background = {
        name = hex.base00;
        opacity = 0.64;
      };
      foreground = hex.base05;
      secondary_background = {
        name = hex.base01;
        opacity = 0.72;
      };
      border = {
        name = hex.base02;
        opacity = 0.42;
      };
      accent = hex.base0D;
    };
    accents = {
      blue = hex.base0D;
      green = hex.base0B;
      magenta = hex.base0E;
      orange = hex.base09;
      purple = hex.base0E;
      red = hex.base08;
      yellow = hex.base0A;
      cyan = hex.base0C;
    };
    list.item.selection = {
      background = hex.base02;
      secondary_background = hex.base03;
    };
  };
}
