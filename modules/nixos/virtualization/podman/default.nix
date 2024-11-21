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
    enable = lib.hdwlinux.mkEnableTagsOpt "podman" [
      "virtualization:podman"
    ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !config.hdwlinux.virtualization.docker.enable;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
