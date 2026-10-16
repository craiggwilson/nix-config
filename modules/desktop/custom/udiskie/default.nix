{
  config.substrate.modules.desktop.custom.udiskie = {
    provides = [ "desktop:custom" ];
    tags = [ "desktop:custom" ];

    homeManager = {
      services.udiskie = {
        enable = true;
        automount = true;
        tray = "auto";
      };
    };
  };
}
