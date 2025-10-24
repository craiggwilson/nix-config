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
    enable = config.lib.hdwlinux.mkEnableOption "podman" "virtualization:podman";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !config.hdwlinux.virtualization.docker.enable;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
