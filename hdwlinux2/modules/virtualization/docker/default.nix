{
  config.substrate.modules.virtualization.docker = {
    tags = [ "virtualization:docker" ];
    nixos = {
      virtualisation.docker = {
        enable = true;
      };
    };
  };
}

