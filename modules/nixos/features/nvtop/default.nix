{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.nvtop;
in
{
  options.hdwlinux.features.nvtop = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config.environment.systemPackages = with pkgs; mkIf cfg.enable [
    nvtopPackages.full
  ];
}
