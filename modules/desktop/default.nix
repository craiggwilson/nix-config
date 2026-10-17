{
  config.substrate.modules.desktop = {
    provides = [
      "desktop"
      "gui"
    ];
    nixos = {
      services.graphical-desktop.enable = true;
    };
  };
}
