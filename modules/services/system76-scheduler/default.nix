{
  config.substrate.modules.services.system76-scheduler = {
    provides = [ "hardware:power" ];

    nixos = {
      services.system76-scheduler.enable = true;
    };
  };
}
