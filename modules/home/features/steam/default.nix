{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.steam;
in
{
  options.hdwlinux.features.steam = with types; {
    enable = mkEnableOpt ["gui" "gaming"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    steam
  ];
}
