{
  config.substrate.modules.desktop = {
    provides = [ "desktop" "gui" ];
    tags = [ "desktop" ];
    nixos = {
      services.graphical-desktop.enable = true;
    };
  };
}
