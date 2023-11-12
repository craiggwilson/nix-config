{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.distrobox;
in
{
  options.hdwlinux.features.distrobox = with types; {
    enable = mkBoolOpt false "Whether or not to enable distrobox.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    distrobox
  ];
}

