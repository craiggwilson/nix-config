{ options, config, lib, pkgs, osConfig, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.direnv;
in
{
  options.hdwlinux.features.direnv = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config.programs.direnv = mkIf cfg.enable {
    enable = true;
    nix-direnv.enable = true;
  };
}
