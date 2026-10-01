{
  # Mako colors from the active palette (theming adapter).
  config.substrate.settings.theming.apps.mako = {
    apply.homeManager =
      { theme, ... }:
      let
        colors = theme.colors.hexWithHashtag;
      in
      {
        services.mako.settings = {
          background-color = colors.base00;
          border-color = colors.base00;
          progress-color = colors.base02;
          text-color = colors.base05;

          "urgency=high" = {
            border-color = colors.base09;
          };
        };
      };
  };
}
