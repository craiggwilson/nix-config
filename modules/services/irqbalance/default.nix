{
  config.substrate.modules.services.irqbalance = {
    provides = [ "hardware:power" ];

    nixos = {
      services.irqbalance.enable = true;
    };
  };
}
