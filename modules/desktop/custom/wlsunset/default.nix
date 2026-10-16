{
  config.substrate.modules.desktop.custom.wlsunset = {
    provides = [ "desktop:custom" ];
    tags = [ "desktop:custom" ];

    homeManager = {
      services.wlsunset = {
        enable = true;
        latitude = "32.7942";
        longitude = "-96.7655";
      };
    };
  };
}
