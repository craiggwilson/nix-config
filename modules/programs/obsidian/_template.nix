# Obsidian theme template.
#
# Receives the colorLib attrset (as returned by lib/colors.nix).
#
# Strategy: define --ctp-X variables from our base16 palette, then reproduce
# the Catppuccin theme CSS verbatim (dark/mocha only, stripped of multi-flavor
# blocks and @settings). All the Catppuccin selectors and rules are kept exactly
# — only the palette source changes.
#
# Mapping (Catppuccin Mocha → base16/base24):
#   ctp-base      = base00  (primary background)
#   ctp-mantle    = base01  (secondary background)
#   ctp-crust     = base11  (darkest background)
#   ctp-surface0  = base02  (borders)
#   ctp-surface1  = base03  (interactive normal)
#   ctp-surface2  = base04
#   ctp-overlay0  = mix(base04, base05, 1/7)
#   ctp-overlay1  = mix(base04, base05, 2/7)
#   ctp-overlay2  = mix(base04, base05, 3/7)
#   ctp-subtext0  = mix(base04, base05, 4/7)
#   ctp-subtext1  = mix(base04, base05, 5/7)
#   ctp-text      = base05  (normal foreground)
#   ctp-red       = base08
#   ctp-maroon    = base12  (bright red / maroon)
#   ctp-peach     = base09
#   ctp-yellow    = base0A
#   ctp-green     = base0B
#   ctp-teal      = base0C
#   ctp-sky       = base15  (bright cyan / sky)
#   ctp-sapphire  = base16  (bright blue / sapphire)
#   ctp-blue      = base0D
#   ctp-lavender  = base07  (accent / lavender)
#   ctp-mauve     = base0E
#   ctp-flamingo  = base0F
#   ctp-rosewater = base06
#   ctp-pink      = base17  (bright magenta / pink)

colorLib:
let
  c = colorLib.rgbString;

  # The base16 palette only has base04 (surface2) and base05 (text) to cover the
  # full overlay/subtext range. We interpolate evenly across that gap to produce
  # the intermediate steps the Catppuccin theme needs for color hierarchy.
  #
  # mix c1 c2 num den  →  c1 + (c2 - c1) * num/den
  #
  #   surface2 = base04               (0/7 of the way from base04 to base05)
  #   overlay0 = mix base04 base05 1 7
  #   overlay1 = mix base04 base05 2 7
  #   overlay2 = mix base04 base05 3 7
  #   subtext0 = mix base04 base05 4 7
  #   subtext1 = mix base04 base05 5 7
  #   text     = base05               (7/7 = base05)
  overlay0 = colorLib.mix colorLib.base04 colorLib.base05 1 7;
  overlay1 = colorLib.mix colorLib.base04 colorLib.base05 2 7;
  overlay2 = colorLib.mix colorLib.base04 colorLib.base05 3 7;
  subtext0 = colorLib.mix colorLib.base04 colorLib.base05 4 7;
  subtext1 = colorLib.mix colorLib.base04 colorLib.base05 5 7;

  # rgba() helper: produces "rgba(R, G, B, alpha)" from a color object and alpha string.
  # Use this where CSS variable interpolation via rgb(var(--x), opacity%) won't work
  # correctly — e.g. --text-selection, where the result must be visually distinguishable.
  rgba = color: alpha:
    let inherit (color) rgb;
    in "rgba(${toString (builtins.elemAt rgb 0)}, ${toString (builtins.elemAt rgb 1)}, ${toString (builtins.elemAt rgb 2)}, ${alpha})";
in
''
  .theme-dark,
  .theme-light {
    --ctp-rosewater: ${c.base06};
    --ctp-flamingo:  ${c.base0F};
    --ctp-pink:      ${c.base17};
    --ctp-mauve:     ${c.base0E};
    --ctp-red:       ${c.base08};
    --ctp-maroon:    ${c.base12};
    --ctp-peach:     ${c.base09};
    --ctp-yellow:    ${c.base0A};
    --ctp-green:     ${c.base0B};
    --ctp-teal:      ${c.base0C};
    --ctp-sky:       ${c.base15};
    --ctp-sapphire:  ${c.base16};
    --ctp-blue:      ${c.base0D};
    --ctp-lavender:  ${c.base07};
    --ctp-text:      ${c.base05};
    --ctp-subtext1:  ${subtext1.rgbString};
    --ctp-subtext0:  ${subtext0.rgbString};
    --ctp-overlay2:  ${overlay2.rgbString};
    --ctp-overlay1:  ${overlay1.rgbString};
    --ctp-overlay0:  ${overlay0.rgbString};
    --ctp-surface2:  ${c.base04};
    --ctp-surface1:  ${c.base03};
    --ctp-surface0:  ${c.base02};
    --ctp-base:      ${c.base00};
    --ctp-mantle:    ${c.base01};
    --ctp-crust:     ${c.base11};

    --hex-pink:      ${colorLib.base17.hexWithHashtag};
    --hex-mauve:     ${colorLib.base0E.hexWithHashtag};
    --hex-red:       ${colorLib.base08.hexWithHashtag};
    --hex-peach:     ${colorLib.base09.hexWithHashtag};
    --hex-yellow:    ${colorLib.base0A.hexWithHashtag};
    --hex-green:     ${colorLib.base0B.hexWithHashtag};
    --hex-teal:      ${colorLib.base0C.hexWithHashtag};
    --hex-sky:       ${colorLib.base15.hexWithHashtag};
    --hex-sapphire:  ${colorLib.base16.hexWithHashtag};
    --hex-blue:      ${colorLib.base0D.hexWithHashtag};
    --hex-lavender:  ${colorLib.base07.hexWithHashtag};

    --color-red-rgb:    var(--ctp-red);
    --color-red:        var(--hex-red);
    --color-orange-rgb: var(--ctp-peach);
    --color-orange:     var(--hex-peach);
    --color-yellow-rgb: var(--ctp-yellow);
    --color-yellow:     var(--hex-yellow);
    --color-green-rgb:  var(--ctp-green);
    --color-green:      var(--hex-green);
    --color-cyan-rgb:   var(--ctp-sapphire);
    --color-cyan:       var(--hex-sapphire);
    --color-blue-rgb:   var(--ctp-blue);
    --color-blue:       var(--hex-blue);
    --color-purple-rgb: var(--ctp-mauve);
    --color-purple:     var(--hex-mauve);
    --color-pink-rgb:   var(--ctp-pink);
    --color-pink:       var(--hex-pink);

    --ctp-accent: var(--ctp-lavender);

    --background-primary:                    rgb(var(--ctp-base));
    --background-primary-rgb:                var(--ctp-base);
    --background-primary-alt:                rgb(var(--ctp-mantle));
    --background-secondary:                  rgb(var(--ctp-mantle));
    --background-secondary-alt:              rgb(var(--ctp-crust));
    --background-modifier-border:            rgb(var(--ctp-surface0));
    --background-modifier-form-field:        rgb(var(--ctp-crust), 30%);
    --background-modifier-form-field-highlighted: rgb(var(--ctp-crust), 22%);
    --background-modifier-box-shadow:        rgb(var(--ctp-crust), 30%);
    --background-modifier-success:           rgb(var(--ctp-green), 90%);
    --background-modifier-success-rgb:       var(--ctp-green);
    --background-modifier-error:             rgb(var(--ctp-red), 90%);
    --background-modifier-error-rgb:         var(--ctp-red);
    --background-modifier-error-hover:       rgb(var(--ctp-red), 100%);
    --background-modifier-cover:             rgb(var(--ctp-crust), 90%);
    --color-accent:                          rgb(var(--ctp-accent));
    --color-accent-1:                        rgb(var(--ctp-accent));
    --color-accent-2:                        rgb(var(--ctp-accent), 90%);
    --text-accent:                           rgb(var(--ctp-accent));
    --text-accent-hover:                     rgb(var(--ctp-accent));
    --text-normal:                           rgb(var(--ctp-text));
    --text-muted:                            rgb(var(--ctp-subtext0));
    --text-muted-rgb:                        var(--ctp-subtext0);
    --text-faint:                            rgb(var(--ctp-surface1));
    --text-error:                            rgb(var(--ctp-red));
    --text-error-hover:                      rgb(var(--ctp-red), 80%);
    --text-highlight-bg:                     rgb(var(--ctp-rosewater), 100%);
    --text-highlight-bg-active:              rgb(var(--ctp-rosewater), 100%);
    --text-selection:                        ${rgba colorLib.base0E "0.35"};
    --text-on-accent:                        rgb(var(--ctp-mantle));
    --text-on-accent-inverted:               rgb(var(--ctp-mantle));
    --interactive-normal:                    rgb(var(--ctp-surface0));
    --interactive-hover:                     rgb(var(--ctp-surface1));
    --interactive-accent:                    rgb(var(--ctp-accent));
    --interactive-accent-rgb:                var(--ctp-accent);
    --interactive-accent-hover:              rgb(var(--ctp-accent));
    --interactive-success:                   rgb(var(--ctp-green));
    --scrollbar-active-thumb-bg:             rgb(var(--ctp-text), 20%);
    --scrollbar-bg:                          rgb(var(--ctp-text), 5%);
    --scrollbar-thumb-bg:                    rgb(var(--ctp-text), 10%);
    --mono-rgb-0:                            var(--ctp-crust);
    --mono-rgb-100:                          var(--ctp-text);
    --color-base-00:  rgb(var(--ctp-crust));
    --color-base-10:  rgb(var(--ctp-mantle));
    --color-base-20:  rgb(var(--ctp-base));
    --color-base-25:  rgb(var(--ctp-surface0));
    --color-base-30:  rgb(var(--ctp-surface1));
    --color-base-35:  rgb(var(--ctp-surface2));
    --color-base-40:  rgb(var(--ctp-overlay0));
    --color-base-50:  rgb(var(--ctp-overlay1));
    --color-base-60:  rgb(var(--ctp-overlay2));
    --color-base-70:  rgb(var(--ctp-subtext0));
    --color-base-100: rgb(var(--ctp-text));
  }

  .theme-dark {
    color-scheme: dark;
    --highlight-mix-blend-mode: lighten;
  }

  .theme-light {
    color-scheme: light;
    --highlight-mix-blend-mode: darken;
  }

  .theme-dark:not(.css-settings-manager),
  .theme-light:not(.css-settings-manager) {
    --blockquote-border-color: rgb(var(--ctp-lavender));
    --ctp-accent: var(--ctp-lavender);
    --divider-color-hover: rgb(var(--ctp-blue));
    --hr-color: rgb(var(--ctp-blue));
    --indentation-guide-color: rgb(var(--ctp-surface1));
    --indentation-guide-color-active: rgb(var(--ctp-sapphire), 70%);
    --indentation-guide-width: 2px;
    --list-marker-color: rgb(var(--ctp-sapphire));
    --checklist-done-color: rgb(var(--ctp-green));
  }

  .theme-dark:not(.css-settings-manager) .workspace-tab-header-inner-close-button:hover,
  .theme-light:not(.css-settings-manager) .workspace-tab-header-inner-close-button:hover {
    box-shadow: none;
  }

  strong,
  .cm-strong,
  .cm-s-obsidian span.cm-formatting-strong,
  .cm-s-obsidian span.cm-strong {
    color: rgb(var(--ctp-sapphire));
  }

  em,
  .cm-em {
    --italic-color: rgb(var(--ctp-green));
  }

  del,
  .cm-strikethrough {
    color: rgb(var(--ctp-maroon));
  }

  .markdown-rendered blockquote,
  .cm-s-obsidian span.cm-quote {
    --blockquote-border-color: rgb(var(--ctp-accent));
    --blockquote-color: rgb(var(--ctp-rosewater));
  }

  .cm-em.cm-strong,
  strong > em,
  em > strong {
    color: rgb(var(--ctp-teal));
  }

  h1,
  .markdown-rendered h1,
  .HyperMD-header-1,
  .HyperMD-list-line .cm-header-1 {
    --h1-color: rgb(var(--ctp-accent));
  }

  h2,
  .markdown-rendered h2,
  .HyperMD-header-2,
  .HyperMD-list-line .cm-header-2 {
    --h2-color: rgb(var(--ctp-accent));
  }

  h3,
  .markdown-rendered h3,
  .HyperMD-header-3,
  .HyperMD-list-line .cm-header-3 {
    --h3-color: rgb(var(--ctp-accent));
  }

  h4,
  .markdown-rendered h4,
  .HyperMD-header-4,
  .HyperMD-list-line .cm-header-4 {
    --h4-color: rgb(var(--ctp-accent));
  }

  h5,
  .markdown-rendered h5,
  .HyperMD-header-5,
  .HyperMD-list-line .cm-header-5 {
    --h5-color: rgb(var(--ctp-accent));
  }

  h6,
  .markdown-rendered h6,
  .HyperMD-header-6,
  .HyperMD-list-line .cm-header-6 {
    --h6-color: rgb(var(--ctp-accent));
  }

  .markdown-rendered mark,
  .cm-s-obsidian span.cm-formatting-highlight,
  .cm-s-obsidian span.cm-highlight {
    background-color: rgb(var(--ctp-rosewater));
    color: var(--text-on-accent);
  }

  .tooltip {
    border: 1px solid rgb(var(--ctp-rosewater), 60%);
    background-color: var(--background-secondary);
    box-shadow: 0 0 4px rgb(var(--ctp-mantle));
    color: rgb(var(--ctp-rosewater), 80%);
  }

  .drag-ghost {
    --drag-ghost-background: var(--background-secondary);
    --drag-ghost-text-color: rgb(var(--ctp-rosewater), 80%);
    border: 1px solid rgb(var(--ctp-rosewater), 60%);
  }

  .tree-item-self.is-clickable.nav-file-title.has-focus[style] {
    --background-modifier-border-focus: var(--color-base-40);
  }

  .suggestion-item.is-selected {
    background-color: rgb(var(--ctp-accent));
    color: var(--text-on-accent);
  }

  .suggestion-item.is-selected .suggestion-flair {
    color: var(--text-on-accent);
  }

  .suggestion-item.mod-complex .suggestion-hotkey {
    background-color: rgb(var(--ctp-surface0));
    color: var(--text-normal);
  }

  .suggestion-item.mod-complex.is-selected .suggestion-note {
    color: var(--text-on-accent);
  }

  .clickable-icon:hover,
  .mod-left-split .workspace-tab-header:hover,
  .mod-right-split .workspace-tab-header:hover {
    --background-modifier-hover: rgb(var(--ctp-pink));
    background-color: rgb(var(--ctp-pink));
    color: var(--text-on-accent);
  }

  .clickable-icon:hover svg,
  .mod-left-split .workspace-tab-header:hover svg,
  .mod-right-split .workspace-tab-header:hover svg {
    color: var(--text-on-accent);
  }

  .clickable-icon.is-active,
  .mod-left-split .workspace-tab-header.is-active,
  .mod-right-split .workspace-tab-header.is-active {
    box-shadow: inset 0 0 4px rgb(var(--ctp-crust)), inset 0 0 6px rgb(var(--ctp-base));
    outline: 1px solid rgb(var(--ctp-surface1));
  }

  .clickable-icon.is-active svg,
  .mod-left-split .workspace-tab-header.is-active svg,
  .mod-right-split .workspace-tab-header.is-active svg {
    color: rgb(var(--ctp-pink));
  }

  .clickable-icon.is-active:hover,
  .clickable-icon.is-active:hover svg,
  .mod-left-split .workspace-tab-header.is-active:hover,
  .mod-left-split .workspace-tab-header.is-active:hover svg,
  .mod-right-split .workspace-tab-header.is-active:hover,
  .mod-right-split .workspace-tab-header.is-active:hover svg {
    background-color: rgb(var(--ctp-pink));
    box-shadow: none;
    color: var(--text-on-accent);
  }

  .workspace-tab-header-inner-close-button:hover {
    background-color: rgb(var(--ctp-red), 50%);
  }

  .workspace .mod-root .workspace-tabs.mod-stacked .workspace-tab-container .workspace-tab-header-inner-close-button:hover,
  .workspace-tab-header.is-active .workspace-tab-header-inner-close-button:hover,
  .modal-close-button:hover {
    background-color: rgb(var(--ctp-red));
    box-shadow: 0 0 2px 1px rgb(var(--ctp-surface1));
    color: rgb(var(--ctp-base));
  }

  .search-input-clear-button:hover,
  .search-input-clear-button:active {
    color: rgb(var(--ctp-red));
  }

  .mod-linux .titlebar-button:hover,
  .mod-windows .titlebar-button:hover {
    background-color: rgb(var(--ctp-pink));
    color: var(--text-on-accent);
  }

  .mod-linux .titlebar-button.mod-close:hover,
  .mod-windows .titlebar-button.mod-close:hover {
    background-color: rgb(var(--ctp-red));
    color: var(--text-on-accent);
  }

  select:focus,
  .dropdown:focus {
    box-shadow: 0 0 0 2px rgb(var(--ctp-blue), 70%);
  }

  textarea:focus,
  input[type=text]:focus,
  input[type=search]:focus,
  input[type=email]:focus,
  input[type=password]:focus,
  input[type=number]:focus,
  textarea:focus-visible,
  input[type=text]:focus-visible,
  input[type=search]:focus-visible,
  input[type=email]:focus-visible,
  input[type=password]:focus-visible,
  input[type=number]:focus-visible {
    box-shadow: 0 0 0 2px rgb(var(--ctp-blue), 70%);
  }

  .checkbox-container {
    box-shadow: 0 0 2px inset rgb(var(--ctp-base));
  }

  .checkbox-container.is-enabled {
    background-color: rgb(var(--ctp-green));
  }

  .prompt {
    --prompt-border-color: rgb(var(--ctp-surface1));
  }

  .prompt .prompt-results {
    background-color: var(--background-secondary);
    box-shadow: inset 0 0 10px rgb(var(--ctp-crust)), inset 0 0 12px rgb(var(--ctp-base));
  }

  .modal {
    border-color: rgb(var(--ctp-surface1));
  }

  /* Nav hover: left border in accent color, no background fill */
  :not(.is-grabbing) .nav-file-title:hover,
  :not(.is-grabbing) .nav-folder-title:hover,
  .tree-item-self.is-clickable:hover {
    --nav-item-background-hover: transparent;
    --nav-item-color-hover: rgb(var(--ctp-text));
    background-color: transparent;
    box-shadow: inset 0 0 0 1px rgb(var(--ctp-accent));
    color: rgb(var(--ctp-text));
  }

  .nav-folder.mod-root > .nav-folder-title:hover {
    background-color: transparent;
    box-shadow: none;
    color: rgb(var(--ctp-text));
  }

  /* Nav active (currently open file/item): full border in accent, normal text */
  .nav-file-title.is-active,
  .nav-folder-title.is-active {
    --nav-item-background-active: transparent;
    --nav-item-color-active: rgb(var(--ctp-text));
    background-color: transparent;
    box-shadow: inset 0 0 0 1px rgb(var(--ctp-accent));
    color: rgb(var(--ctp-text));
  }

  /* Selected tree item (bookmarks panel etc.): full border in mauve/purple */
  .tree-item-self.is-selected {
    background-color: transparent;
    box-shadow: inset 0 0 0 1px rgb(var(--ctp-mauve));
    color: rgb(var(--ctp-mauve));
  }

  .tree-item-self.is-selected .tree-item-icon {
    color: rgb(var(--ctp-mauve));
  }

  body:not(.is-grabbing) .tree-item-self.is-active:hover,
  .tree-item-self.is-active {
    --nav-item-color-active: rgb(var(--ctp-text));
    --nav-item-background-active: transparent;
    background-color: transparent;
    box-shadow: inset 0 0 0 1px rgb(var(--ctp-accent));
    color: rgb(var(--ctp-text));
  }

  body:not(.is-grabbing) .tree-item-self.is-active:hover .tree-item-icon,
  .tree-item-self.is-active .tree-item-icon {
    --icon-color: rgb(var(--ctp-accent));
  }

  .nav-file-tag {
    background-color: rgb(var(--ctp-surface0));
    color: var(--text-normal);
    outline: 1px solid rgb(var(--ctp-surface1));
  }

  .is-active .nav-file-tag {
    box-shadow: inset 0 0 2px rgb(var(--ctp-crust)), inset 0 0 4px rgb(var(--ctp-mantle));
  }

  .search-suggest-item.is-selected {
    background-color: rgb(var(--ctp-accent));
    color: var(--text-on-accent);
  }

  .search-suggest-item.is-selected .search-suggest-info-text {
    color: var(--text-on-accent);
  }

  .search-result-file-matched-text {
    background-color: rgb(var(--ctp-rosewater));
    color: var(--text-on-accent);
  }

  .horizontal-tab-nav-item:hover,
  .vertical-tab-nav-item:hover {
    background-color: rgb(var(--ctp-accent));
    color: var(--text-on-accent);
  }

  .horizontal-tab-nav-item.is-active,
  .vertical-tab-nav-item.is-active {
    background-color: rgb(var(--ctp-accent));
  }

  body:not(.is-phone) .horizontal-tab-nav-item.is-active,
  body:not(.is-phone) .vertical-tab-nav-item.is-active {
    --ctp-accent: var(--ctp-mauve);
    background-color: rgb(var(--ctp-accent));
    color: var(--text-on-accent);
  }

  .status-bar-item.mod-clickable:hover {
    --background-modifier-hover: rgb(var(--ctp-accent));
    color: var(--text-on-accent);
  }

  .canvas-controls button:hover {
    --interactive-hover: rgb(var(--ctp-accent));
    --text-normal: var(--text-on-accent);
  }

  .cm-s-obsidian span.cm-error {
    color: rgb(var(--ctp-red));
  }

  .cm-s-obsidian span.cm-formatting-quote {
    color: rgb(var(--ctp-accent));
  }

  .callout {
    border-color: rgb(var(--callout-color), 60%);
    background-color: rgb(var(--callout-color), 10%);
  }

  .is-flashing,
  .cm-s-obsidian .is-flashing .cm-url {
    background-color: rgb(var(--ctp-rosewater));
    color: var(--text-on-accent);
  }

  .markdown-rendered button.copy-code-button {
    background-color: rgb(var(--ctp-crust));
  }

  .workspace-leaf.mod-active .search-result.has-focus .tree-item-self,
  .workspace-leaf.mod-active .search-result-file-match.has-focus {
    box-shadow: inset 0 0 0 1px rgb(var(--ctp-accent));
  }

  .mod-settings input.slider {
    --slider-track-background: rgb(var(--ctp-accent));
  }

  .community-item.is-selected,
  .community-item.is-selected:hover {
    --interactive-accent: rgb(var(--ctp-mauve));
  }

  .community-item .flair:not(.mod-pop) {
    --tag-background: rgb(var(--ctp-accent));
    --tag-color: var(--text-on-accent);
  }

  .theme-dark .mermaid .mindmap-node text {
    fill: var(--text-on-accent) !important;
  }
''
