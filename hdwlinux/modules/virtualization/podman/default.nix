{
  config.substrate.modules.virtualization.podman = {
    tags = [ "virtualization:podman" ];
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
