{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.virtualization.docker;
in
{
  options.hdwlinux.features.virtualization.docker = with types; {
    enable = mkEnableOpt ["virtualization:docker"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
    };
  };
}
