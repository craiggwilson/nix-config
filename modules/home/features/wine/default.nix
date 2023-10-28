{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.wine;
in
{
  options.hdwlinux.features.wine = with types; {
    enable = mkBoolOpt false "Whether or not to enable wine.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    #wineWowPackages.stable
    winetricks
    wineWowPackages.waylandFull
  ];
}
