{
  config.substrate.modules.services.upower = {
    provides = [ "hardware:power" ];

    nixos = {
      services.upower.enable = true;
    };
  };
}
