{
  config.substrate.modules.desktop.shells.custom.hyprpaper = {
    tags = [ "desktop:shells:custom" ];

    homeManager =
      {
        config,
        lib,
        ...
      }:
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

        # Overrides home-manager's own string-valued definition.
        systemd.user.services.hyprpaper.Unit.ConditionEnvironment = lib.mkForce "HDWLINUX_SHELL=custom";
      };
  };
}
