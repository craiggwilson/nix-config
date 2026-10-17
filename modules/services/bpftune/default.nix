{
  config.substrate.modules.services.bpftune = {
    provides = [
      "services:bpftune"
      "hardware:power"
    ];

    nixos = {
      services.bpftune.enable = true;
    };
  };
}
