{
  config.substrate.modules.virtualization.docker = {
    provides = [ "virtualization:docker" ];
    tags = [ "virtualization:docker" ];
    nixos = {
      virtualisation.docker = {
        enable = true;
      };
    };
  };
}
