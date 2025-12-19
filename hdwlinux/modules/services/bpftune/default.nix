{
  config.substrate.modules.services.bpftune = {
    nixos = {
      services.bpftune.enable = true;
    };
  };
}

