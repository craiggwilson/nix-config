{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.neofetch;
in
{
  options.hdwlinux.features.neofetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable neofetch.";
  };

  config.environment.systemPackages = with pkgs; mkIf cfg.enable [
    neofetch
  ];
}