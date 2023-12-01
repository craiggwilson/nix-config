{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.protonup-qt;
in
{
  options.hdwlinux.features.protonup-qt = with types; {
    enable = mkEnableOpt ["gui" "gaming"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    protonup-qt
  ];
}
