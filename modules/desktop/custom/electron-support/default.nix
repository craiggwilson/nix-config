{
  config.substrate.modules.desktop.custom.electron-support = {
    tags = [ "desktop:custom" ];

    homeManager =
      { ... }:
      {
        home.sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };

        xdg.configFile."electron-flags.conf".text = ''
          --enable-features=UseOzonePlatform
          --ozone-platform=wayland
          --wayland-text-input-version=3
        '';
      };
  };
}

