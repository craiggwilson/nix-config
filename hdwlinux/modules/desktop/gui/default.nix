{
  config.substrate.modules.desktop.gui = {
    tags = [ "gui" ];
    nixos = {
      services.graphical-desktop.enable = true;
    };
  };
}

