{
  config.substrate.modules.services.virtualization.podman = {
    tags = [ "capability:virtualization:podman" ];
    nixos =
      { config, ... }:
      {
        virtualisation.podman = {
          enable = true;
          dockerCompat = !config.virtualisation.docker.enable;
          defaultNetwork.settings.dns_enabled = true;
        };
      };
  };
}
