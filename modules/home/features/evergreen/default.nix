{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.evergreen;
in
{
  options.hdwlinux.features.evergreen = with types; {
    enable = mkBoolOpt false "Whether or not to enable evergreen.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    hdwlinux.evergreen
  ];
}

