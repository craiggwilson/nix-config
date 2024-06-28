{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.discord;
in
{
  options.hdwlinux.features.discord = with types; {
    enable = mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    discord
  ];
}
