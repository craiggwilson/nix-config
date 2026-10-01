{
  config.substrate.modules.desktop.custom.hyprpaper = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, ... }:
      let
        # Every palette wallpaper is loaded and hyprpaper rotates them on the
        # `rand` interval.
        wallpapers = config.theming.palette.wallpapers;
      in
      {
        services.hyprpaper = {
          enable = true;
          settings = {
            splash = false;
            ipc = "off";

            wallpaper = map (w: {
              monitor = "";
              path = "${w}";
              fit_mode = "cover";
            }) wallpapers;

            rand = 900;
          };
        };
      };
  };
}
