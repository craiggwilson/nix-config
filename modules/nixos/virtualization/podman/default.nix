{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.virtualization.podman;
in
{
  options.hdwlinux.virtualization.podman = {
    enable = lib.mkOption {
      description = "Whether to enable podman.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "virtualization:podman" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !config.hdwlinux.virtualization.docker.enable;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
