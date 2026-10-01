{
  # Palette-derived terminal theme, served by the substrate theming adapter:
  # applied whenever a theme is active, theme-independent code here.
  config.substrate.settings.theming.apps.ghostty = {
    enabled = { config, ... }: true;

    apply.homeManager =
      { theme, ... }:
      let
        colors = theme.colors.hexWithHashtag;
      in
      {
        programs.ghostty.themes.hdwlinux = {
          background = colors.base00;
          cursor-color = colors.base06;
          foreground = colors.base05;
          palette = [
            "0=${colors.base03}"
            "1=${colors.base08}"
            "2=${colors.base0B}"
            "3=${colors.base0A}"
            "4=${colors.base0D}"
            "5=${colors.base17}"
            "6=${colors.base0C}"
            "7=${colors.base05}"
            "8=${colors.base04}"
            "9=${colors.base08}"
            "10=${colors.base0B}"
            "11=${colors.base0A}"
            "12=${colors.base0D}"
            "13=${colors.base17}"
            "14=${colors.base0C}"
            "15=${colors.base07}"
          ];
          selection-background = colors.base02;
          selection-foreground = colors.base05;
        };
      };
  };
}
