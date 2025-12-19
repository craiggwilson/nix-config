{
  config.substrate.modules.services.irqbalance = {
    nixos = {
      services.irqbalance.enable = true;
    };
  };
}

