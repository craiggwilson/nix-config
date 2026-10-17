{
  config.substrate.modules.virtualization.docker = {
    provides = [ "virtualization:docker" ];
    nixos = {
      virtualisation.docker = {
        enable = true;
      };
    };
  };
}
