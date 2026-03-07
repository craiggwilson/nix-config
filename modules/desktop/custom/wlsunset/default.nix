{
  config.substrate.modules.desktop.custom.wlsunset = {
    tags = [ "desktop:custom" ];

    homeManager =
      { ... }:
      {
        services.wlsunset = {
          enable = true;
          latitude = "32.7942";
          longitude = "-96.7655";
        };
      };
  };
}

