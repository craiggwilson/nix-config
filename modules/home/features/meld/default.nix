{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.meld;
in
{
  options.hdwlinux.features.meld = with types; {
    enable = mkBoolOpt false "Whether or not to enable meld.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    meld
  ];
}
