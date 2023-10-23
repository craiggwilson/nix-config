{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.nvtop;
in
{
  options.hdwlinux.features.nvtop = with types; {
    enable = mkBoolOpt false "Whether or not to enable nvtop.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    nvtop
  ];
}
