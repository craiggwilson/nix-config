# Shared color utility library.
#
# Takes a raw colors attrset (bare hex strings without #), an ansiColors
# attrset (16 named ANSI slots to bare hex strings), and a paletteToAnsi
# attrset (bare hex -> ANSI slot name covering the full palette).
#
# Returns a color library where each palette entry (base00..base0F etc.) is a
# color object carrying all representations as plain attributes, plus top-level
# constructor functions and precomputed map attrsets.
#
# Fractions are passed as (num, den) pairs to avoid Nix integer division
# truncation — Nix has no float literals in pure evaluation contexts.
#
# Color object shape:
#   {
#     hex            = "89b4fa";
#     hexWithHashtag = "#89b4fa";
#     rgb            = [137 180 250];
#     rgbString      = "137 180 250";
#     ansi           = "blue";        # ANSI slot name, or null if not in palette
#   }
#
# Usage:
#   colorLib = import ./colors.nix colors ansiColors paletteToAnsi;
#   colorLib.base00.hex                                # => "1e1e2e"
#   colorLib.base00.hexWithHashtag                     # => "#1e1e2e"
#   colorLib.base00.rgb                                # => [30 30 46]
#   colorLib.base00.rgbString                          # => "30 30 46"
#   colorLib.base00.ansi                               # => "black"
#   colorLib.base0D.ansi                               # => "blue"
#   colorLib.fromHex "89b4fa"                          # => color object
#   colorLib.fromHex "#89b4fa"                         # => color object (# stripped)
#   colorLib.fromRgb [137 180 250]                     # => color object
#   colorLib.fromRgb "137 180 250"                     # => color object
#   colorLib.fromAnsi "blue"                           # => color object
#   colorLib.fromAnsi "brightBlue"                     # => color object
#   colorLib.mix colorLib.base04 colorLib.base05 1 6   # => color object
#   colorLib.lighten colorLib.base04 1 4               # => color object
#   colorLib.darken colorLib.base05 1 4                # => color object
#   colorLib.hex                                       # => { base00 = "1e1e2e"; … }
#   colorLib.hexWithHashtag                            # => { base00 = "#1e1e2e"; … }
#   colorLib.rgb                                       # => { base00 = [30 30 46]; … }
#   colorLib.rgbString                                 # => { base00 = "30 30 46"; … }
#   colorLib.ansi.base00                               # => "black"  (baseXX -> slot name)
#   colorLib.ansi.black                                # => color object for black slot
#   colorLib.ansi.brightBlack                          # => color object for brightBlack slot
colors: ansiColors_: paletteToAnsi_:
let
  ansiColors = if ansiColors_ == null then { } else ansiColors_;
  paletteToAnsi = if paletteToAnsi_ == null then { } else paletteToAnsi_;

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

  # Strip a leading # from a hex string if present.
  stripHash =
    s:
    if builtins.substring 0 1 s == "#" then builtins.substring 1 (builtins.stringLength s - 1) s else s;

  # Parse a bare 6-character hex string into an [r g b] integer list.
  parseHexToList = hex: [
    (parseByte (builtins.substring 0 2 hex))
    (parseByte (builtins.substring 2 2 hex))
    (parseByte (builtins.substring 4 2 hex))
  ];

  # Encode an [r g b] integer list into a bare 6-character hex string.
  listToHex =
    c:
    encodeByte (builtins.elemAt c 0)
    + encodeByte (builtins.elemAt c 1)
    + encodeByte (builtins.elemAt c 2);

  # Parse a "r g b" space-separated string into an [r g b] integer list.
  parseRgbString = s: map builtins.fromJSON (builtins.filter (x: x != "") (builtins.split " " s));

  # Convert an [r g b] list to a "r g b" space-separated string.
  listToRgbString = c: builtins.concatStringsSep " " (map toString c);

  # bare hex -> ANSI slot name (null if not in palette).
  hexToAnsiSlot = hex: paletteToAnsi.${hex} or null;

  # ── Color object constructor ────────────────────────────────────────────────

  # Build a color object from a bare 6-character hex string.
  mkColor =
    hex:
    let
      rgbList = parseHexToList hex;
    in
    {
      hex = hex;
      hexWithHashtag = "#" + hex;
      rgb = rgbList;
      rgbString = listToRgbString rgbList;
      ansi = hexToAnsiSlot hex;
    };

  # ── Constructor functions ───────────────────────────────────────────────────

  # Build a color object from a hex string (leading # stripped transparently).
  fromHex = h: mkColor (stripHash h);

  # Build a color object from an [r g b] list or a "r g b" space-separated string.
  fromRgb =
    c: if builtins.isList c then mkColor (listToHex c) else mkColor (listToHex (parseRgbString c));

  # Build a color object from an ANSI slot name (e.g. "blue", "brightBlue").
  fromAnsi = slot: mkColor ansiColors.${slot};

  # ── Transformation functions ────────────────────────────────────────────────

  # Mix two color objects. t = num/den in [0, 1]: 0 = c1, 1 = c2.
  mix =
    c1: c2: num: den:
    mkColor (listToHex [
      (lerpInt (builtins.elemAt c1.rgb 0) (builtins.elemAt c2.rgb 0) num den)
      (lerpInt (builtins.elemAt c1.rgb 1) (builtins.elemAt c2.rgb 1) num den)
      (lerpInt (builtins.elemAt c1.rgb 2) (builtins.elemAt c2.rgb 2) num den)
    ]);

  # Lighten a color object by mixing toward white by amount/den.
  lighten =
    c: amount: den:
    mix c (mkColor "ffffff") amount den;

  # Darken a color object by mixing toward black by amount/den.
  darken =
    c: amount: den:
    mix c (mkColor "000000") amount den;

  # ── Palette color objects ───────────────────────────────────────────────────

  palette = builtins.mapAttrs (_: h: mkColor h) colors;

  # ── Precomputed map attrsets ────────────────────────────────────────────────

  hexMap = builtins.mapAttrs (_: c: c.hex) palette;
  hexWithHashtagMap = builtins.mapAttrs (_: c: c.hexWithHashtag) palette;
  rgbMap = builtins.mapAttrs (_: c: c.rgb) palette;
  rgbStringMap = builtins.mapAttrs (_: c: c.rgbString) palette;

  # baseXX -> ANSI slot name string (null where not in the ANSI palette).
  ansiNameMap = builtins.mapAttrs (_: c: c.ansi) palette;

  # ANSI slot name -> color object (one entry per slot: black, brightBlack, …).
  ansiSlotToColor = builtins.mapAttrs (_: h: mkColor h) ansiColors;

  # Bidirectional ansi attrset: baseXX -> slot name, and slot name -> color object.
  ansiMap = ansiNameMap // ansiSlotToColor;

in
palette
// {
  inherit
    fromHex
    fromRgb
    fromAnsi
    mix
    lighten
    darken
    ;

  hex = hexMap;
  hexWithHashtag = hexWithHashtagMap;
  rgb = rgbMap;
  rgbString = rgbStringMap;
  ansi = ansiMap;
}
