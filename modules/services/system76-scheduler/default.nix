{
  config.substrate.modules.services.system76-scheduler = {
    provides = [ "services:system76-scheduler" "hardware:power" ];

    nixos = {
      services.system76-scheduler.enable = true;
    };
  };
}
