{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.virtualization.podman;
in
{
  options.hdwlinux.features.virtualization.podman = with types; {
    enable = mkEnableOpt [ "virtualization:podman" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !config.hdwlinux.features.virtualization.docker.enable;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
