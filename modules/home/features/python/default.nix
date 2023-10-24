{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.python;
in
{
  options.hdwlinux.features.python = with types; {
    enable = mkBoolOpt false "Whether or not to enable python.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    python311
    python311Packages.pip
  ];
}
