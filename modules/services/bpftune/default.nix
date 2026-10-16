{
  config.substrate.modules.services.bpftune = {
    provides = [ "hardware:power" ];

    nixos = {
      services.bpftune.enable = true;
    };
  };
}
