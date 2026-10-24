{
  config.substrate.modules.services.bpftune = {
    tags = [ "capability:performance" ];
    nixos = {
      services.bpftune.enable = true;
    };
  };
}
