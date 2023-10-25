{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.grimblast;
in
{
  options.hdwlinux.features.grimblast = with types; {
    enable = mkBoolOpt false "Whether or not to enable grimblast.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    grimblast
  ];
}
