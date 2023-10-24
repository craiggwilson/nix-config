{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.pciutils;
in
{
  options.hdwlinux.features.pciutils = with types; {
    enable = mkBoolOpt false "Whether or not to enable pciutils.";
  };

  config.environment.systemPackages = with pkgs; mkIf cfg.enable [
    pciutils
  ];
}
