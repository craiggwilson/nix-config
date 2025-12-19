{
  config.substrate.modules.desktop.custom.udiskie = {
    tags = [ "desktop:custom" ];

    homeManager =
      { ... }:
      {
        services.udiskie = {
          enable = true;
          automount = true;
          tray = "auto";
        };
      };
  };
}

