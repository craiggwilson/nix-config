{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.docker;
in
{
  options.hdwlinux.packages.docker = with types; {
    enable = mkBoolOpt false "Whether or not to enable docker.";
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.docker.storageDriver = "btrfs"; #TODO: get this from disko???

    hdwlinux.user.extraGroups = [ "docker" ];
  };
}
