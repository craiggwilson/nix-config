{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.atlas-cli;
in
{
  options.hdwlinux.features.atlas-cli = with types; {
    enable = mkBoolOpt false "Whether or not to enable atlas-cli.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    hdwlinux.atlas-cli
  ];
}
