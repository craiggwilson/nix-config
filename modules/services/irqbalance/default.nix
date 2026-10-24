{
  config.substrate.modules.services.irqbalance = {
    tags = [ "capability:performance" ];
    nixos = {
      services.irqbalance.enable = true;
    };
  };
}
