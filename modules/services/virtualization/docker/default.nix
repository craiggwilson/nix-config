{
  config.substrate.modules.services.virtualization.docker = {
    tags = [ "capability:virtualization:docker" ];
    nixos = {
      virtualisation.docker = {
        enable = true;
      };
    };
  };
}
