{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gimp;
in
{
  options.hdwlinux.features.gimp = with types; {
    enable = mkBoolOpt false "Whether or not to enable gimp.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    gimp
  ];
}
