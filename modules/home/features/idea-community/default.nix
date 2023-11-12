{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.idea-community;
in
{
  options.hdwlinux.features.idea-community = with types; {
    enable = mkBoolOpt false "Whether or not to enable idea-community.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    jetbrains.idea-community
  ];
}
