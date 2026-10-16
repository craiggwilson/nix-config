{
  config.substrate.modules.services.irqbalance = {
    provides = [ "services:irqbalance" "hardware:power" ];

    nixos = {
      services.irqbalance.enable = true;
    };
  };
}
