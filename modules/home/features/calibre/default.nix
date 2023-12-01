{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.calibre;
in
{
  options.hdwlinux.features.calibre = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    calibre
  ];
}
