{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.grimblast;
in
{
  options.hdwlinux.features.grimblast = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    grimblast
  ];
}
