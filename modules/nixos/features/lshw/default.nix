{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.lshw;
in
{
  options.hdwlinux.features.lshw = with types; {
    enable = mkBoolOpt false "Whether or not to enable lshw.";
  };

  config.environment.systemPackages = with pkgs; mkIf cfg.enable [
    lshw
  ];
}
