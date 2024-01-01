{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gamescope;
in
{
  options.hdwlinux.features.gamescope = with types; {
    enable = mkEnableOpt ["gui" "gaming"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    gamescope
  ];
}
