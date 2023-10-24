{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.goland;
in
{
  options.hdwlinux.features.goland = with types; {
    enable = mkBoolOpt false "Whether or not to enable goland.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    jetbrains.goland
  ];
}
