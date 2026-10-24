{
  config.substrate.modules.services.system76-scheduler = {
    tags = [ "capability:performance" ];
    nixos = {
      services.system76-scheduler.enable = true;
    };
  };
}
