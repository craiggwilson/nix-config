{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.slack;
in
{
  options.hdwlinux.features.slack = with types; {
    enable = mkEnableOpt ["gui" "work"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
      slack
  ];
}
