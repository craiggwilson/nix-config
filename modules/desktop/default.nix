{
  config.substrate.modules.desktop = {
    provides = [ "gui" ];
    tags = [ "desktop" ];
    nixos = {
      services.graphical-desktop.enable = true;
    };
  };
}
