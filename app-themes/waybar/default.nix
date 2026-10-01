{
  # Waybar palette CSS as a runtime template (theming adapter): the stylesheet
  # @imports colors.css, and waybar reloads its style on change, so a theme
  # switch repaints without a rebuild.
  config.substrate.settings.theming.apps.waybar = {
    enabled = { config, ... }: config.programs ? waybar && config.programs.waybar.enable;

    templates =
      { theme, ... }:
      {
        "waybar/colors.css" = {
          content = ''
            @define-color base00 ${theme.colors.hexWithHashtag.base00};
            @define-color base01 ${theme.colors.hexWithHashtag.base01};
            @define-color base02 ${theme.colors.hexWithHashtag.base02};
            @define-color base03 ${theme.colors.hexWithHashtag.base03};
            @define-color base04 ${theme.colors.hexWithHashtag.base04};
            @define-color base05 ${theme.colors.hexWithHashtag.base05};
            @define-color base06 ${theme.colors.hexWithHashtag.base06};
            @define-color base07 ${theme.colors.hexWithHashtag.base07};
            @define-color base08 ${theme.colors.hexWithHashtag.base08};
            @define-color base09 ${theme.colors.hexWithHashtag.base09};
            @define-color base0A ${theme.colors.hexWithHashtag.base0A};
            @define-color base0B ${theme.colors.hexWithHashtag.base0B};
            @define-color base0C ${theme.colors.hexWithHashtag.base0C};
            @define-color base0D ${theme.colors.hexWithHashtag.base0D};
            @define-color base0E ${theme.colors.hexWithHashtag.base0E};
            @define-color base0F ${theme.colors.hexWithHashtag.base0F};
          '';
          dest = "$HOME/.config/waybar/colors.css";
        };
      };
  };
}
