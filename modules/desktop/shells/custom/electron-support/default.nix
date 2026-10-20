{
  config.substrate.modules.desktop.shells.custom.electron-support = {
    tags = [ "desktop:shells:custom" ];

    homeManager = {
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
