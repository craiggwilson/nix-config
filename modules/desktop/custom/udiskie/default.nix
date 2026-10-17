{
  config.substrate.modules.desktop.custom.udiskie = {
    provides = [ "desktop:custom:udiskie" ];
    homeManager = {
      services.udiskie = {
        enable = true;
        automount = true;
        tray = "auto";
      };
    };
  };
}
