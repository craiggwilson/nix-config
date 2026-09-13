# Renders the hdwlinux theme colors into a Noctalia custom palette.
#
# Expects the colorLib attrset returned by lib/colors.nix and returns the
# payload consumed by programs.noctalia.customPalettes. Noctalia falls back to
# the dark variant for both modes when light is omitted, so only dark is
# emitted while the theme is dark-only.
#
# Role/terminal assignments reproduce the "Catppuccin Mocha Lavender" community
# palette, expressed with the theme's base00..base17 colors so it tracks the
# active palette.
colors:
let
  hex = colors.hexWithHashtag;
in
{
  dark = {
    mError = hex.base08;
    mHover = hex.base03;
    mOnError = hex.base00;
    mOnHover = hex.base05;
    mOnPrimary = hex.base00;
    mOnSecondary = hex.base00;
    mOnSurface = hex.base05;
    mOnSurfaceVariant = hex.base05;
    mOnTertiary = hex.base00;
    mOutline = hex.base04;
    mPrimary = hex.base07;
    mSecondary = hex.base17;
    mShadow = hex.base11;
    mSurface = hex.base00;
    mSurfaceVariant = hex.base02;
    mTertiary = hex.base0E;

    terminal = {
      background = hex.base00;
      cursor = hex.base07;
      cursorText = hex.base00;
      foreground = hex.base05;
      selectionBg = hex.base04;
      selectionFg = hex.base05;

      normal = {
        black = hex.base03;
        blue = hex.base0D;
        cyan = hex.base0C;
        green = hex.base0B;
        magenta = hex.base17;
        red = hex.base08;
        white = hex.base05;
        yellow = hex.base0A;
      };

      bright = {
        black = hex.base04;
        blue = hex.base0D;
        cyan = hex.base0C;
        green = hex.base0B;
        magenta = hex.base17;
        red = hex.base08;
        white = hex.base07;
        yellow = hex.base0A;
      };
    };
  };
}
