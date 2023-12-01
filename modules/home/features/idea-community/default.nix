{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.idea-community;
in
{
  options.hdwlinux.features.idea-community = with types; {
    enable = mkEnableOpt ["gui" "programming"] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    jetbrains.idea-community
  ];
}
