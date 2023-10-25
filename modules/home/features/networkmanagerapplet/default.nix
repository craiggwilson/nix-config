{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.networkmanagerapplet;
in
{
  options.hdwlinux.features.networkmanagerapplet = with types; {
    enable = mkBoolOpt false "Whether or not to enable networkmanagerapplet.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    networkmanagerapplet
  ];
}
