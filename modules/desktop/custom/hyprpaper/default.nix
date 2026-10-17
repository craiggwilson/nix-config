{
  config.substrate.modules.desktop.custom.hyprpaper = {
    provides = [ "desktop:custom:hyprpaper" ];
    homeManager =
      { config, ... }:
      let
        wallpaper = config.hdwlinux.theme.wallpaper;
      in
      {
        services.hyprpaper = {
          enable = true;
          settings = {
            splash = false;
            ipc = "off";

            wallpaper = {
              monitor = "";
              path = "${wallpaper}";
              fit_mode = "cover";
            };
          };
        };
      };
  };
}
