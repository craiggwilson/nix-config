{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.atlas-cli;
in
{
  options.hdwlinux.packages.atlas-cli = with types; {
    enable = mkBoolOpt false "Whether or not to enable atlas-cli.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        hdwlinux.atlas-cli
    ];
  };
}

