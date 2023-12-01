{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.goland;
in
{
  options.hdwlinux.features.goland = with types; {
    enable = mkEnableOpt ["gui" "programming"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    jetbrains.goland
  ];
}
