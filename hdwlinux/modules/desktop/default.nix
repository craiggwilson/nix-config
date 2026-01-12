{
  config.substrate.modules.desktop = {
    tags = [ "desktop" ];
    nixos = {
      services.graphical-desktop.enable = true;
    };
  };
}
