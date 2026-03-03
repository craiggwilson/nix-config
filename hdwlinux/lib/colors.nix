# Shared color utility library.
#
# Takes a raw colors attrset (bare hex strings without #) and returns it
# enriched with mix/lighten/darken functions. Both the top-level attrset and
# withHashtag carry these functions, operating on bare and #-prefixed strings
# respectively.
#
# Fractions are passed as (num, den) pairs to avoid Nix integer division
# truncation — Nix has no float literals in pure evaluation contexts.
#
# Usage:
#   colorLib = import ./colors.nix { base00 = "1e1e2e"; base05 = "cdd6f4"; ... };
#   colorLib.mix "585b70" "cdd6f4" 1 2          # => "9398b2"
#   colorLib.withHashtag.mix "#585b70" "#cdd6f4" 1 2  # => "#9398b2"
#   colorLib.lighten "585b70" 1 4               # => "9da0b3"
#   colorLib.darken "cdd6f4" 1 4                # => "9aa0b7"
colors:
let
  hexDigits = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
    "A" = 10;
    "B" = 11;
    "C" = 12;
    "D" = 13;
    "E" = 14;
    "F" = 15;
  };

  intDigits = [
    "0"
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "a"
    "b"
    "c"
    "d"
    "e"
    "f"
  ];

  # Parse a two-character hex byte string into an integer 0-255.
  parseByte = s: hexDigits.${builtins.substring 0 1 s} * 16 + hexDigits.${builtins.substring 1 1 s};

  # Encode an integer 0-255 as a two-character lowercase hex string.
  encodeByte =
    n: builtins.elemAt intDigits (n / 16) + builtins.elemAt intDigits (builtins.bitAnd n 15);

  # Parse a bare 6-character hex color string into { r, g, b } integers.
  parseColor = hex: {
    r = parseByte (builtins.substring 0 2 hex);
    g = parseByte (builtins.substring 2 2 hex);
    b = parseByte (builtins.substring 4 2 hex);
  };

  # Encode { r, g, b } integers into a bare 6-character hex string.
  encodeColor = c: encodeByte c.r + encodeByte c.g + encodeByte c.b;

  # Clamp an integer to [0, 255].
  clamp =
    n:
    if n < 0 then
      0
    else if n > 255 then
      255
    else
      n;

  # Linear interpolation between two integers: a + (b - a) * num / den.
  lerpInt =
    a: b: num: den:
    clamp (a + (b - a) * num / den);

  # Mix two bare hex color strings. t = num/den in [0, 1].
  # mix c1 c2 0 1 = c1, mix c1 c2 1 1 = c2.
  mix =
    c1: c2: num: den:
    let
      a = parseColor c1;
      b = parseColor c2;
    in
    encodeColor {
      r = lerpInt a.r b.r num den;
      g = lerpInt a.g b.g num den;
      b = lerpInt a.b b.b num den;
    };

  # Lighten a bare hex color string by mixing toward white by amount/den.
  lighten =
    c: amount: den:
    mix c "ffffff" amount den;

  # Darken a bare hex color string by mixing toward black by amount/den.
  darken =
    c: amount: den:
    mix c "000000" amount den;

  # Strip a leading # from a color string.
  stripHash = s: builtins.substring 1 (builtins.stringLength s - 1) s;

  # Variants of the functions that accept and return #-prefixed strings.
  mixH =
    c1: c2: num: den:
    "#" + mix (stripHash c1) (stripHash c2) num den;
  lightenH =
    c: amount: den:
    "#" + lighten (stripHash c) amount den;
  darkenH =
    c: amount: den:
    "#" + darken (stripHash c) amount den;

  withHashtag = builtins.mapAttrs (_: v: "#" + v) colors // {
    mix = mixH;
    lighten = lightenH;
    darken = darkenH;
  };

in
colors
// {
  inherit
    withHashtag
    mix
    lighten
    darken
    ;
}
