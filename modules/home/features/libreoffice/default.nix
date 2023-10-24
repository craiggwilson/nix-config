{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.libreoffice;
in
{
  options.hdwlinux.features.libreoffice = with types; {
    enable = mkBoolOpt false "Whether or not to enable libreoffice.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    libreoffice
  ];
}
