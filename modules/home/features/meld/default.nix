{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.meld;
in
{
  options.hdwlinux.features.meld = with types; {
    enable = mkEnableOpt ["gui" "programming"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    meld
  ];
}
