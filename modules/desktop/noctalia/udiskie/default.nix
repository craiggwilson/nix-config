{
  config.substrate.modules.desktop.noctalia.udiskie = {
    provides = [
      "desktop:noctalia:udiskie"
      "desktop:noctalia"
      "desktop:noctalia:niri"
    ];
    homeManager = {
      services.udiskie = {
        enable = true;
        automount = true;
        tray = "never";
      };
    };
  };
}
