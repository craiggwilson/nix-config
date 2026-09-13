{
  config.substrate.modules.desktop.noctalia.udiskie = {
    tags = [ "desktop:noctalia" ];

    homeManager = {
      services.udiskie = {
        enable = true;
        automount = true;
        tray = "never";
      };
    };
  };
}
