{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.podman;
in
{
  options.hdwlinux.features.podman = with types; {
    enable = mkBoolOpt false "Whether or not to enable podman.";
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !config.hdwlinux.features.docker.enable;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
