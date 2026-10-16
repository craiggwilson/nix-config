{
  config.substrate.modules.services.upower = {
    provides = [ "services:upower" "hardware:power" ];

    nixos = {
      services.upower.enable = true;
    };
  };
}
