{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.wire;
in
{
  options.hdwlinux.features.wire = with types; {
    enable = mkBoolOpt false "Whether or not to enable wire.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    wire
  ];
}

