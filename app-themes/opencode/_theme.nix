# Returns a programs.opencode.themes-compatible attrset for the "hdwlinux" theme.
# Expects the colorLib attrset (as returned by lib/colors.nix). Each baseXX
# entry is a color object; opencode themes use "#rrggbb" hex strings.
colors:
let
  # Shorthand aliases using hexWithHashtag strings
  bg = colors.base00.hexWithHashtag; # darkest background
  surface = colors.base01.hexWithHashtag; # panel / sidebar background
  overlay = colors.base02.hexWithHashtag; # selection / mid background
  muted = colors.base03.hexWithHashtag; # comments, subtle borders
  subtle = colors.base04.hexWithHashtag; # muted text
  text = colors.base05.hexWithHashtag; # primary text
  light = colors.base06.hexWithHashtag; # light accents
  bright = colors.base07.hexWithHashtag; # brightest text / headings
  red = colors.base08.hexWithHashtag; # errors, removed diff
  orange = colors.base09.hexWithHashtag; # constants, numbers
  yellow = colors.base0A.hexWithHashtag; # warnings, emphasis
  green = colors.base0B.hexWithHashtag; # strings, success, added diff
  cyan = colors.base0C.hexWithHashtag; # special, info
  blue = colors.base0D.hexWithHashtag; # functions, primary accent
  mauve = colors.base0E.hexWithHashtag; # keywords, secondary accent
  brown = colors.base0F.hexWithHashtag; # deprecated, punctuation
in
{
  defs = {
    inherit
      bg
      surface
      overlay
      muted
      subtle
      text
      light
      bright
      red
      orange
      yellow
      green
      cyan
      blue
      mauve
      brown
      ;
  };

  theme = {
    # ── Core UI ──────────────────────────────────────────────────────────────
    primary = blue;
    secondary = mauve;
    accent = cyan;
    error = red;
    warning = yellow;
    success = green;
    info = cyan;

    inherit text;
    textMuted = subtle;
    background = bg;
    backgroundPanel = surface;
    backgroundElement = overlay;

    border = overlay;
    borderActive = blue;
    borderSubtle = muted;

    # ── Diff ─────────────────────────────────────────────────────────────────
    diffAdded = green;
    diffRemoved = red;
    diffContext = subtle;
    diffHunkHeader = blue;
    diffHighlightAdded = green;
    diffHighlightRemoved = red;
    diffAddedBg = surface;
    diffRemovedBg = surface;
    diffContextBg = bg;
    diffLineNumber = muted;
    diffAddedLineNumberBg = surface;
    diffRemovedLineNumberBg = surface;

    # ── Markdown ─────────────────────────────────────────────────────────────
    markdownText = text;
    markdownHeading = blue;
    markdownLink = cyan;
    markdownLinkText = blue;
    markdownCode = green;
    markdownBlockQuote = muted;
    markdownEmph = orange;
    markdownStrong = yellow;
    markdownHorizontalRule = muted;
    markdownListItem = blue;
    markdownListEnumeration = cyan;
    markdownImage = cyan;
    markdownImageText = blue;
    markdownCodeBlock = text;

    # ── Syntax ───────────────────────────────────────────────────────────────
    syntaxComment = muted;
    syntaxKeyword = mauve;
    syntaxFunction = blue;
    syntaxVariable = text;
    syntaxString = green;
    syntaxNumber = orange;
    syntaxType = yellow;
    syntaxOperator = mauve;
    syntaxPunctuation = text;
  };
}
